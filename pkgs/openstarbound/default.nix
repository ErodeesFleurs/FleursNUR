{
  stdenv,
  fetchurl,
  autoPatchelfHook,
  unzip,
  tar,
  ...
}:

stdenv.mkDerivation rec {
  name = "OpenStarbound-${version}";
  version = "Nightly";
  src = fetchurl {
    url = "https://nightly.link/OpenStarbound/OpenStarbound/workflows/build/main/OpenStarbound-Linux-Client.zip";
    sha256 = "";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    unzip
    tar
  ];

  unpackPhase = ''
    # Unzip the downloaded file
    mkdir -p $TMPDIR/build
    unzip $src -d $TMPDIR/build

    # Extract dist.tar
    tar -xvf $TMPDIR/build/dist.tar -C $TMPDIR/build
  '';
  installPhase = ''
    mkdir -p $out/{linux, assets}

    cp -r $TMPDIR/build/linux $out
    cp -r $TMPDIR/build/assets $out
  '';

  meta = {
    description = "OpenStarbound is a free open-source Starbound server implementation";
    homepage = "https://github.com/OpenStarbound/OpenStarbound";
    license = licenses.mit;
    platforms = stdenv.lib.platforms.linux;
  };
}
