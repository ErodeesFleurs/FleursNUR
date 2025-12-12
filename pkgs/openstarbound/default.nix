{
  lib,
  fetchFromGitHub,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  imagemagick,
  icoutils,
  callPackage,
  clangStdenv,
  cmake,
  pkg-config,
  zlib,
  zstd,
  xorg,
  glew,
  libpng,
  jemalloc,
  freetype,
  libvorbis,
  libopus,
  sdl3,
  re2,
  cpptrace,
  libcpr,
  # Optional path configurations
  starboundAssetsPath ? null,
  storageDir ? null,
  logDir ? null,
  modDir ? null,
  extraAssetDirs ? [ ],
}:

let
  version = "nightly-2025-12-12";
  rev = "f0abd78";

  # Default paths (can be overridden at build time or runtime)
  defaultStarboundAssets = "\${STARBOUND_ASSETS:-$HOME/.local/share/Steam/steamapps/common/Starbound/assets}";
  defaultStorageDir = "\${XDG_DATA_HOME:-$HOME/.local/share}/OpenStarbound/storage";
  defaultLogDir = "\${XDG_DATA_HOME:-$HOME/.local/share}/OpenStarbound/logs";
  defaultModDir = "\${XDG_DATA_HOME:-$HOME/.local/share}/OpenStarbound/mods";

  # Use custom paths if provided, otherwise use defaults
  starboundAssets =
    if starboundAssetsPath != null then starboundAssetsPath else defaultStarboundAssets;
  storagePath = if storageDir != null then storageDir else defaultStorageDir;
  logPath = if logDir != null then logDir else defaultLogDir;
  modPath = if modDir != null then modDir else defaultModDir;

  # Build asset directories list
  assetDirectories = [
    starboundAssets
    modPath
  ]
  ++ extraAssetDirs;

  # Force using the repository's imgui package
  imguiPkg = callPackage ../imgui { };
in

clangStdenv.mkDerivation (finalAttrs: {
  pname = "openstarbound";
  inherit version;

  src = fetchFromGitHub {
    owner = "OpenStarbound";
    repo = "OpenStarbound";
    inherit rev;
    fetchSubmodules = false;
    hash = "sha256-kXAZdwppiWSbWzYsjAT+O12kVxolDwGKTGhl0YlzGfs=";
  };

  sourceRoot = "source/source";

  nativeBuildInputs = [
    cmake
    pkg-config
    makeWrapper
    copyDesktopItems
    imagemagick
    icoutils
  ];

  buildInputs = [
    zlib
    zstd
    xorg.libSM
    xorg.libXi
    glew
    libpng
    jemalloc
    freetype
    libvorbis
    libopus
    sdl3
    re2
    cpptrace
    imguiPkg
    libcpr
  ];

  cmakeFlags = [
    (lib.cmakeFeature "CMAKE_BUILD_TYPE" "Release")
    (lib.cmakeBool "STAR_USE_JEMALLOC" true)
  ];

  postPatch = ''
    # Use custom CMakeLists.txt for Nix build
    cp ${./patches/CMakeLists.txt} CMakeLists.txt
    mkdir -p dist
  '';

  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall

    # Basic layout and binaries
    mkdir -p $out/bin $out/libexec/openstarbound $out/share/openstarbound

    # copy build artifacts if present (some builds may place files in ../dist)
    cp -r ../dist/* $out/libexec/openstarbound/ >/dev/null 2>&1 || true

    # Ensure main binary is installed and executable
    if [ -f ../dist/starbound ]; then
      install -Dm755 ../dist/starbound $out/libexec/openstarbound/starbound
    elif [ -f $out/libexec/openstarbound/starbound ]; then
      chmod +x $out/libexec/openstarbound/starbound || true
    fi

    # Install repository-provided fallback assets (small asset pack shipped with repo)
    if [ -d ../../assets ]; then
      mkdir -p $out/share/openstarbound/assets
      cp -r ../../assets/* $out/share/openstarbound/
    fi

    # Build asset directories JSON array (simple, trimmed)
    ASSET_DIRS_JSON=""
    ${lib.concatMapStringsSep " " (dir: ''
      ASSET_DIRS_JSON="$ASSET_DIRS_JSON\"${dir}\","
    '') assetDirectories}
    ASSET_DIRS_JSON="$ASSET_DIRS_JSON\"$out/share/openstarbound/assets\""
    ASSET_DIRS_JSON="$(echo "$ASSET_DIRS_JSON" | sed 's/,$//')"

    # Create wrapper script that prepares a temporary boot config at runtime
    makeWrapper $out/libexec/openstarbound/starbound $out/bin/openstarbound \
      --run 'export XDG_DATA_HOME=''${XDG_DATA_HOME:-$HOME/.local/share}' \
      --run 'export XDG_CONFIG_HOME=''${XDG_CONFIG_HOME:-$HOME/.config}' \
      --run 'STORAGE_DIR="${storagePath}"' \
      --run 'LOG_DIR="${logPath}"' \
      --run 'MOD_DIR="${modPath}"' \
      --run 'mkdir -p "$STORAGE_DIR" "$LOG_DIR" "$MOD_DIR"' \
      --run 'BOOT_CONFIG=$(mktemp -t openstarbound-boot.XXXXXXXXXX.json)' \
      --run 'trap "rm -f \"$BOOT_CONFIG\"" EXIT' \
      --run 'cat > "$BOOT_CONFIG" << EOF
    {
      "assetDirectories": [ $ASSET_DIRS_JSON ],
      "storageDirectory": "$STORAGE_DIR",
      "logDirectory": "$LOG_DIR"
    }
    EOF' \
      --run 'for a in "$@"; do if [ "$a" = "--print-bootconfig" ]; then cat "$BOOT_CONFIG"; exit 0; fi; done' \
      --add-flags '-bootconfig "$BOOT_CONFIG"'

    # Install a single icon if available (keep it simple)
    if [ -f ../client/icon.png ]; then
      mkdir -p $out/share/icons/hicolor/128x128/apps
      cp ../client/icon.png $out/share/icons/hicolor/128x128/apps/openstarbound.png || true
    fi

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "openstarbound";
      desktopName = "OpenStarbound";
      comment = "Open-source Starbound client with improvements";
      exec = "openstarbound %U";
      icon = "openstarbound";
      categories = [ "Game" ];
      keywords = [
        "starbound"
        "game"
        "multiplayer"
      ];
      terminal = false;
      startupNotify = false;
      mimeTypes = [ ];
    })
  ];

  passthru = {
    inherit rev;
    # Allow creating custom builds with different paths
    override = args: finalAttrs.finalPackage.overrideAttrs (old: args);
    withPaths =
      {
        starboundAssets ? null,
        storage ? null,
        logs ? null,
        mods ? null,
        extraAssets ? [ ],
      }:
      finalAttrs.finalPackage.override {
        starboundAssetsPath = starboundAssets;
        storageDir = storage;
        logDir = logs;
        modDir = mods;
        extraAssetDirs = extraAssets;
      };
  };

  meta = {
    description = "Open-source client for Starbound with quality-of-life improvements";
    longDescription = ''
      OpenStarbound is a client-side mod that adds features and improvements
      to Starbound.

      Note: Requires Starbound to be installed (typically via Steam) to access
      the game's assets.

      This package can be customized with different paths at build time:

        pkgs.openstarbound.override {
          starboundAssetsPath = "/custom/path/to/assets";
          storageDir = "/custom/storage";
          modDir = "/custom/mods";
        }

      Or use the convenience function:

        pkgs.openstarbound.withPaths {
          starboundAssets = "/custom/path/to/assets";
          storage = "/custom/storage";
          mods = "/custom/mods";
          extraAssets = [ "/extra/assets/dir" ];
        }
    '';
    homepage = "https://github.com/OpenStarbound/OpenStarbound";
    maintainers = [ ];
    platforms = lib.platforms.linux;
    mainProgram = "openstarbound";
  };
})
