{
  lib,
  stdenv,
  writeShellApplication,
  ...
}:

let
  openstarbound-raw = import ./openstarbound.nix {
    inherit
      lib
      stdenv
      fetchurl
      autoPatchelfHook
      makeWrapper
      unzip
      libGL
      libGLU
      libSM
      libICE
      libX11
      libXext
      libgcc
      ;
  };
in
writeShellApplication {
  name = "openstarbound-${openstarbound-raw.version}";
  runtimeInputs = [
    openstarbound-raw
  ];
  text = ''
    steam_assets_dir="$HOME/.local/share/Steam/steamapps/common/Starbound/assets"
    storage_dir="$HOME/.local/share/xStarbound/storage"
    log_dir="$HOME/.local/share/xStarbound/logs"
    mod_dir="$HOME/.local/share/xStarbound/mods"

    mkdir -p "$storage_dir"
    tmp_cfg="$(mktemp -t openstarbound.XXXXXXXX)"

    cat << EOF > "$tmp_cfg"
      {
      "assetDirectories" : [
        "$gog_assets_dir",
        "$steam_assets_dir",
        "$mod_dir",
        "../assets/"
      ],

      "storageDirectory" : "$storage_dir",
      "logDirectory" : "$log_dir"
    }
    EOF

    exec ${openstarbound-raw}/linux/starbound \
      -bootconfig "$tmp_cfg" \
      "$@"

    rm "$tmp_cfg"
  '';
}
