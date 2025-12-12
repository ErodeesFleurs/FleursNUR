# fleurs-nur

**Fleurs's Personal [NUR](https://github.com/nix-community/NUR) Repository**

## Usage

### With Flakes

```nix
{
  inputs.fleurs-nur.url = "github:ErodeesFleurs/fleurs-nur";
  # ...
}
```

Then in your configuration:

```nix
# Add packages to system
environment.systemPackages = [
  inputs.fleurs-nur.packages.${system}.openstarbound
];

# Or use as overlay
nixpkgs.overlays = [ inputs.fleurs-nur.overlays.default ];
```

### With NUR

Add to your NixOS configuration:

```nix
{
  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
  };
}
```

Then use packages:

```nix
environment.systemPackages = with pkgs.nur.repos.fleurs; [
  openstarbound
  uudeck
];
```

### As Overlay

```nix
{
  nixpkgs.overlays = [
    (import (builtins.fetchTarball "https://github.com/ErodeesFleurs/fleurs-nur/archive/master.tar.gz") + "/overlay.nix")
  ];
}
```

## Modules (NixOS & Home Manager)

This repository exports NixOS modules under `modules/` and Home Manager modules under `home-modules/`.

- NixOS module: `modules/openstarbound.nix`
- Home Manager module: `home-modules/openstarbound.nix`

Both modules expose a similar option set under `programs.openstarbound` (system) and `home.programs.openstarbound` (home).

Available options

- `enable` (bool): Enable the OpenStarbound integration.
- `package` (package | null): Use a custom package or let the module build one with configured paths.
- `starboundAssetsPath` (string | null): Path to Starbound's official game assets.
- `storageDir` (string | null): Directory for game saves and universe data. If null uses XDG default.
- `logDir` (string | null): Directory for game log files. If null uses XDG default.
- `modDir` (string | null): Directory for custom mods. If null uses XDG default.
- `extraAssetDirs` (list of string): Additional asset directories to load.
- `installDesktopFile` (bool): Whether to create a desktop file (default true).
- `installIcon` (bool): Whether to install the application icon (default true).
