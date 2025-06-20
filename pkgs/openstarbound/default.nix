{
  lib,
  stdenv,
  writeShellApplication,
  fetchFromGitHub,
  clangStdenv,
  gnumake,
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
  SDL2,
  re2,
  ...
}:

let
  openstarbound-raw = clangStdenv.mkDerivation rec {
    pname = "openstarbound-raw";
    version = "nightly";

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
      SDL2
      re2
    ];

    nativeBuildInputs = [
      gnumake
      cmake
      pkg-config
    ];

    src = fetchFromGitHub ({
      owner = "OpenStarbound";
      repo = "OpenStarbound";
      rev = "0dcecb8";
      fetchSubmodules = false;
      sha256 = "sha256-lk9gYvuhQGDmvsbI3DTmN9lg0hL9khKziG94z8vLIRA=";
    });

    sourceRoot = "source/source";

    enableParallelBuilding = true;

    cmakeFlags = [
      "-DCMAKE_INSTALL_PREFIX=$out"
      "-DCMAKE_BUILD_TYPE=Release"
      "-DSTAR_USE_JEMALLOC=ON"
    ];

    postPatch = ''
      cp ${./patches/CMakeLists.txt} CMakeLists.txt
      mkdir -p dist
    '';

    installPhase = ''
      mkdir -p $out/linux
      mkdir -p $out/assets
      mkdir -p $out/bin
      ls -la ../../
      echo "Copying files"
      ls -la
      cp -r ../dist/* $out/linux
      cp -r ../../assets/* $out/assets
      install -Dm755 $out/linux/starbound $out/bin/openstarbound
    '';
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
