{
  lib,
  makeWrapper,
  clangStdenv,
  callPackage,
  fetchFromGitHub,
  cmake,
  pkg-config,
  imagemagick,
  icoutils,
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
  # optional overrides for paths
  starboundAssetsPath ? null,
  storageDir ? null,
  logDir ? null,
  modDir ? null,
  extraAssetDirs ? [ ],
}:

let
  version = "nightly-2025-12-12";

  # Import the heavy build (game.nix) from the same directory. The importer
  # may pass through the same set of build inputs so the heavy derivation
  # is constructed consistently.
  game = import ./game.nix {
    inherit
      lib
      fetchFromGitHub
      clangStdenv
      cmake
      pkg-config
      imagemagick
      icoutils
      zlib
      zstd
      xorg
      glew
      libpng
      jemalloc
      freetype
      libvorbis
      libopus
      sdl3
      re2
      cpptrace
      libcpr
      ;
    inherit
      starboundAssetsPath
      storageDir
      logDir
      modDir
      extraAssetDirs
      ;
  };
in

clangStdenv.mkDerivation {
  pname = "openstarbound";
  inherit version;

  nativeBuildInputs = [ makeWrapper ];
  # declare the heavy build as a build input so Nix will build it first and
  # make its outputs available for copying into this wrapper's $out.
  buildInputs = [ game ];

  installPhase = ''
        runHook preInstall

        mkdir -p $out/bin $out/libexec/openstarbound $out/share/openstarbound

        # copy runtime outputs (binaries + fallback assets) from heavy build
        cp -r ${game}/libexec/openstarbound $out/libexec/ || true
        cp -r ${game}/share/openstarbound $out/share/ || true

        # write a small runtime wrapper script that composes a boot config at run-time
        cat > $out/bin/openstarbound <<'SH'
    #!/bin/sh -e

    # Resolve this script's prefix in the Nix store so we can find sibling libexec/share
    SELF=$(readlink -f "$0")
    BIN_DIR=$(dirname "$SELF")
    PREFIX=$(dirname "$BIN_DIR")

    STARBOUND_BIN="$PREFIX/libexec/openstarbound/starbound"
    FALLBACK_ASSETS="$PREFIX/share/openstarbound/assets"

    # XDG defaults
    if [ -z "$XDG_DATA_HOME" ]; then
      XDG_DATA_HOME="$HOME/.local/share"
    fi
    if [ -z "$XDG_CONFIG_HOME" ]; then
      XDG_CONFIG_HOME="$HOME/.config"
    fi

    STORAGE_DIR="$XDG_DATA_HOME/OpenStarbound/storage"
    LOG_DIR="$XDG_DATA_HOME/OpenStarbound/logs"
    MOD_DIR="$XDG_DATA_HOME/OpenStarbound/mods"

    mkdir -p "$STORAGE_DIR" "$LOG_DIR" "$MOD_DIR"
    BOOT_CONFIG=$(mktemp -t openstarbound-boot.XXXXXXXXXX.json)
    trap 'rm -f "$BOOT_CONFIG"' EXIT

    # Assemble asset directories (runtime precedence: env STARBOUND_ASSETS, user mods, packaged fallback)
    ASSETS_JSON=""
    if [ -n "$STARBOUND_ASSETS" ]; then
      ASSETS_JSON="$ASSETS_JSON\"$STARBOUND_ASSETS\","
    fi
    if [ -n "$MOD_DIR" ]; then
      ASSETS_JSON="$ASSETS_JSON\"$MOD_DIR\","
    fi
    ASSETS_JSON="$ASSETS_JSON\"$FALLBACK_ASSETS\""
    ASSETS_JSON="$(echo "$ASSETS_JSON" | sed 's/,$//')"

    cat > "$BOOT_CONFIG" <<JSON
    {
      "assetDirectories": [ $ASSETS_JSON ],
      "storageDirectory": "$STORAGE_DIR",
      "logDirectory": "$LOG_DIR"
    }
    JSON

    # Support helper flag that prints the generated boot config
    for a in "$@"; do
      if [ "$a" = "--print-bootconfig" ]; then
        cat "$BOOT_CONFIG"
        exit 0
      fi
    done

    exec "$STARBOUND_BIN" -bootconfig "$BOOT_CONFIG" "$@"
    SH
        chmod +x $out/bin/openstarbound

        runHook postInstall
  '';

  meta = with lib; {
    description = "OpenStarbound wrapper (light) depending on separate game build";
    platforms = lib.platforms.linux;
  };

  passthru = {
    # expose the heavy derivation so callers can build it directly:
    heavy = game;
  };
}
