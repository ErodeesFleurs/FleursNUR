{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  unzip,
  libGL,
  libGLU,
  libSM,
  libICE,
  libX11,
  libXext,
  libgcc,
  ...
}:

stdenv.mkDerivation rec {
  name = "OpenStarbound-${version}";
  version = "Nightly";
  src = fetchurl {
    url = "https://nightly.link/OpenStarbound/OpenStarbound/workflows/build/main/OpenStarbound-Linux-Client.zip";
    sha256 = "sha256-KARChrAZHrVPcGZb4Mkt6oCfQb5V/T+wU/8Qi/L8zHQ=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    unzip

    # Required libraries
    libGL
    libGLU
    libSM
    libICE
    libX11
    libXext
    libgcc
  ];

  unpackPhase = ''
    # Unzip the downloaded file
    mkdir -p $TMPDIR/build
    unzip $src -d $TMPDIR/build

    # Extract client.tar
    tar -xvf $TMPDIR/build/client.tar -C $TMPDIR/build
  '';
  installPhase = ''
    mkdir -p $out/{linux, assets}

    cp -r $TMPDIR/build/client_distribution/linux $out
    cp -r $TMPDIR/build/client_distribution/assets $out
  '';

  meta = {
    description = "OpenStarbound is a free open-source Starbound server implementation";
    homepage = "https://github.com/OpenStarbound/OpenStarbound";
  };
}
