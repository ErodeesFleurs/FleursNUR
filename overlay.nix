# You can use this file as a nixpkgs overlay. This is useful in the
# case where you don't want to add the whole NUR namespace to your
# configuration.

self: super:

let
  nurPkgs = import ./default.nix { pkgs = super; };
in
nurPkgs
