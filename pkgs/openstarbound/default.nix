{
  lib,
  fetchFromGitHub,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  imagemagick,
  imgui,
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
    imgui
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

        # Install binaries
        mkdir -p $out/bin $out/libexec/openstarbound
        cp -r ../dist/* $out/libexec/openstarbound/

        # Install the main binary
        install -Dm755 $out/libexec/openstarbound/starbound $out/libexec/openstarbound/starbound

        # Install game assets
        mkdir -p $out/share/openstarbound
        cp -r ../../assets $out/share/openstarbound/

        # Build asset directories JSON array
        ASSET_DIRS_JSON=""
        ${lib.concatMapStringsSep "\n" (dir: ''
          ASSET_DIRS_JSON="$ASSET_DIRS_JSON\"${dir}\","
        '') assetDirectories}
        ASSET_DIRS_JSON="$ASSET_DIRS_JSON\"$out/share/openstarbound/assets\""

        # Create wrapper script with configured paths
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
      "assetDirectories": [
        $ASSET_DIRS_JSON
      ],
      "storageDirectory": "$STORAGE_DIR",
      "logDirectory": "$LOG_DIR"
    }
    EOF' \
          --add-flags '-bootconfig "$BOOT_CONFIG"'

        # Install icon - convert from .ico to .png at multiple resolutions
        mkdir -p $out/share/icons/hicolor/{16x16,32x32,48x48,128x128,256x256}/apps

        # Use the starbound.ico from the source
        if [ -f ../client/starbound.ico ]; then
          convert ../client/starbound.ico[0] -resize 16x16 $out/share/icons/hicolor/16x16/apps/openstarbound.png
          convert ../client/starbound.ico[0] -resize 32x32 $out/share/icons/hicolor/32x32/apps/openstarbound.png
          convert ../client/starbound.ico[0] -resize 48x48 $out/share/icons/hicolor/48x48/apps/openstarbound.png
          convert ../client/starbound.ico[0] -resize 128x128 $out/share/icons/hicolor/128x128/apps/openstarbound.png
          convert ../client/starbound.ico[0] -resize 256x256 $out/share/icons/hicolor/256x256/apps/openstarbound.png
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
