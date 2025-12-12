# fleurs-nur

**Fleurs's Personal [NUR](https://github.com/nix-community/NUR) Repository**

![Build and populate cache](https://github.com/ErodeesFleurs/fleurs-nur/workflows/Build%20and%20populate%20cache/badge.svg)

## Features

This NUR repository uses an **auto-discovery system** for packages, making it easy to maintain:

- **Automatic Package Discovery**: Just add a directory with `default.nix` to `pkgs/` and it's automatically available
- **Clean Structure**: No empty boilerplate directories
- **Simple Overlay**: Easy integration with your NixOS configuration
- **CI/CD Ready**: Automated builds and caching

## Structure

```
fleurs-nur/
├── pkgs/              # Package definitions (auto-discovered)
│   ├── openstarbound/ # Each subdirectory with default.nix becomes a package
│   ├── imgui/
│   └── uudeck/
├── default.nix        # Auto-discovers and exports all packages
├── overlay.nix        # Nixpkgs overlay for easy integration
├── flake.nix          # Flake interface
└── ci.nix             # CI configuration
```

## Available Packages

- **openstarbound**: OpenStarbound game client with SDL3 support
- **imgui**: Dear ImGui library with SDL3 bindings
- **uudeck**: UU Game Booster for Steam Deck

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

## Adding New Packages

Simply create a new directory in `pkgs/` with a `default.nix` file:

```bash
mkdir pkgs/my-package
cat > pkgs/my-package/default.nix << 'EOF'
{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "my-package";
  version = "1.0.0";
  # ...
}
EOF
```

The package will be automatically discovered and available as `my-package`.

## Development

Build a specific package:

```bash
nix build .#openstarbound
```

Build all packages:

```bash
nix flake check
```

Update dependencies:

```bash
nix flake update
```

## License

See individual package licenses in their respective directories.