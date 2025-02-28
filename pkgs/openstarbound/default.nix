{
  lib,
  stdenv,
  writeShellApplication,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  unzip,
  libGL,
  libGLU,
  libSM,
  libICE,
  libX11,
  libXext,
  libgcc,
  glibc,
  alsa-lib,
  pipewire,
  wayland,
  ...
}:

let
  openstarbound-raw =
    let
      libraries = [
        libGL
        libGLU
        libSM
        libICE
        libX11
        libXext
        libgcc
        pipewire
        alsa-lib
        wayland
      ];
    in
    stdenv.mkDerivation rec {
      name = "OpenStarbound-${version}";
      version = "Nightly";
      src = fetchurl {
        url = "https://nightly.link/OpenStarbound/OpenStarbound/workflows/build/main/OpenStarbound-Linux-Client.zip";
        sha256 = "sha256-/5goflh8E6e4fWwpdI5cMwFqCW1LsTXDTtp9jHPzFP4=";
      };

      buildInputs = [
        pipewire
        alsa-lib
        wayland
        libGL
        libGLU
        libSM
        libICE
        libX11
        libXext
        libgcc
      ];

      nativeBuildInputs = [
        autoPatchelfHook
        makeWrapper
        unzip
      ];

      postPatchelfHook = ''
        substituteInPlace services/audio/audio_sandbox_hook_linux.cc \
        --replace \
          '/usr/share/alsa/' \
          '${alsa-lib}/share/alsa/' \
        --replace \
          '/usr/lib/x86_64-linux-gnu/gconv/' \
          '${glibc}/lib/gconv/' \
        --replace \
          '/usr/share/locale/' \
          '${glibc}/share/locale/'
      '';

      unpackPhase = ''
        # Unzip the downloaded file
        mkdir -p $TMPDIR/build
        unzip $src -d $TMPDIR/build

        # Extract client.tar
        tar -xvf $TMPDIR/build/client.tar -C $TMPDIR/build
      '';

      installPhase = ''
        mkdir -p $out/linux
        mkdir -p $out/assets
        mkdir -p $out/bin

        cp -r $TMPDIR/build/client_distribution/linux $out
        cp -r $TMPDIR/build/client_distribution/assets $out

        makeWrapper $out/linux/starbound $out/bin/openstarbound \
          --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath libraries}
      '';

      meta = {
        description = "OpenStarbound is a free open-source Starbound server implementation";
        homepage = "https://github.com/OpenStarbound/OpenStarbound";
        platforms = [ "x86_64-linux" ];
        mainProgram = "openstarbound";
      };
    };

in

writeShellApplication {
  name = "openstarbound-${openstarbound-raw.version}";
  runtimeInputs = [ openstarbound-raw ];
  text = ''
    steam_assets_dir="$HOME/.local/share/Steam/steamapps/common/Starbound/assets"
    storage_dir="$HOME/.local/share/OpenStarbound/storage"
    log_dir="$HOME/.local/share/OpenStarbound/logs"
    mod_dir="$HOME/.local/share/OpenStarbound/mods"

    mkdir -p "$storage_dir"
    tmp_cfg="$(mktemp -t openstarbound.XXXXXXXX)"

    cat << EOF > "$tmp_cfg"
    {
        "assetDirectories": [
        "$steam_assets_dir",
        "$mod_dir",
        "../assets"
        ],
        "storageDirectory": "$storage_dir",
        "logDirectory": "$log_dir"
    }
    EOF

    openstarbound \
      -bootconfig "$tmp_cfg"
      "$@"

    rm "$tmp_cfg"
  '';
}
