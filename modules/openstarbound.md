# OpenStarbound NixOS Module

This module provides a declarative way to configure OpenStarbound on NixOS systems.

## Quick Start

Add to your `configuration.nix`:

```nix
{
  programs.openstarbound.enable = true;
}
```

Then rebuild your system:

```bash
sudo nixos-rebuild switch
```

## Module Options

### `programs.openstarbound.enable`

**Type**: `boolean`

**Default**: `false`

Enable OpenStarbound on your system. This will install the package and optionally configure paths.

### `programs.openstarbound.package`

**Type**: `null or package`

**Default**: `null`

The OpenStarbound package to use. If `null`, the module will automatically build a package using your configured paths.

**Example**:
```nix
programs.openstarbound.package = pkgs.openstarbound;
```

### `programs.openstarbound.starboundAssetsPath`

**Type**: `null or string`

**Default**: `null`

Path to Starbound's official game assets directory.

**Common Locations**:
- Standard Steam: `"$HOME/.local/share/Steam/steamapps/common/Starbound/assets"`
- Flatpak Steam: `"$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Starbound/assets"`
- Custom: Any path where you have Starbound installed

**Example**:
```nix
programs.openstarbound.starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
```

### `programs.openstarbound.storageDir`

**Type**: `null or string`

**Default**: `null` (uses `$XDG_DATA_HOME/OpenStarbound/storage`)

Directory for game saves and universe data.

**Example**:
```nix
programs.openstarbound.storageDir = "/mnt/games/OpenStarbound/storage";
```

### `programs.openstarbound.logDir`

**Type**: `null or string`

**Default**: `null` (uses `$XDG_DATA_HOME/OpenStarbound/logs`)

Directory for game log files.

**Example**:
```nix
programs.openstarbound.logDir = "/var/log/openstarbound";
```

### `programs.openstarbound.modDir`

**Type**: `null or string`

**Default**: `null` (uses `$XDG_DATA_HOME/OpenStarbound/mods`)

Directory for custom mods.

**Example**:
```nix
programs.openstarbound.modDir = "$HOME/.local/share/OpenStarbound/mods";
```

### `programs.openstarbound.extraAssetDirs`

**Type**: `list of string`

**Default**: `[]`

Additional asset directories to load. Useful for workshop content or custom asset packs.

**Example**:
```nix
programs.openstarbound.extraAssetDirs = [
  "$HOME/OpenStarbound/custom-assets"
  "/mnt/shared/starbound-mods"
];
```

### `programs.openstarbound.installDesktopFile`

**Type**: `boolean`

**Default**: `true`

Whether to install the .desktop file for application menu integration.

### `programs.openstarbound.installIcon`

**Type**: `boolean`

**Default**: `true`

Whether to install the application icon.

## Configuration Examples

### Basic Configuration

Minimal configuration with defaults:

```nix
{
  programs.openstarbound.enable = true;
}
```

This will:
- Install OpenStarbound
- Look for Starbound assets in the default Steam location
- Use XDG directories for storage, logs, and mods

### Custom Steam Location

For Flatpak Steam users:

```nix
{
  programs.openstarbound = {
    enable = true;
    starboundAssetsPath = "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Starbound/assets";
  };
}
```

### External Storage

Store game data on a separate drive:

```nix
{
  programs.openstarbound = {
    enable = true;
    starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
    storageDir = "/mnt/games/OpenStarbound/storage";
    logDir = "/mnt/games/OpenStarbound/logs";
    modDir = "/mnt/games/OpenStarbound/mods";
  };
}
```

### Multiple Asset Directories

Load additional content from multiple locations:

```nix
{
  programs.openstarbound = {
    enable = true;
    starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
    extraAssetDirs = [
      "$HOME/OpenStarbound/workshop-content"
      "$HOME/OpenStarbound/custom-assets"
      "/mnt/shared/starbound-mods"
    ];
  };
}
```

### Development Setup

Configuration for mod development:

```nix
{
  programs.openstarbound = {
    enable = true;
    starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
    storageDir = "$HOME/Development/starbound-test/saves";
    logDir = "$HOME/Development/starbound-test/logs";
    modDir = "$HOME/Development/starbound-test/mods";
    extraAssetDirs = [
      "$HOME/Development/starbound-test/test-assets"
    ];
  };
}
```

### Server Setup

Configuration for a dedicated server environment:

```nix
{
  programs.openstarbound = {
    enable = true;
    starboundAssetsPath = "/srv/starbound/assets";
    storageDir = "/srv/starbound/storage";
    logDir = "/var/log/starbound";
    modDir = "/srv/starbound/mods";
  };
}
```

### Using Custom Package

If you want full control over the package:

```nix
{
  programs.openstarbound = {
    enable = true;
    package = pkgs.openstarbound.override {
      # Your custom overrides
    };
  };
}
```

**Note**: When providing a custom package, path options like `starboundAssetsPath` will be ignored.

## Integration with Other Modules

### With Steam

```nix
{
  programs.steam.enable = true;
  
  programs.openstarbound = {
    enable = true;
    # Automatically uses Steam's install location
  };
}
```

### With Home Manager

If using as a system module alongside home-manager:

```nix
# configuration.nix
{
  programs.openstarbound = {
    enable = true;
    starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
  };
}

# home.nix
{ pkgs, ... }:
{
  # User-specific configuration
  home.file.".config/openstarbound/custom.json".text = ''
    {
      "customSettings": true
    }
  '';
}
```

## Environment Variables

The module sets environment variables when paths are configured:

```nix
{
  programs.openstarbound = {
    enable = true;
    starboundAssetsPath = "/custom/path";
  };
}
```

This automatically sets `STARBOUND_ASSETS=/custom/path` system-wide.

## Troubleshooting

### Module Not Found

If you get "option 'programs.openstarbound' not found":

1. Make sure you've imported the module in your flake:
   ```nix
   {
     inputs.fleurs-nur.url = "github:ErodeesFleurs/fleurs-nur";
     
     outputs = { nixpkgs, fleurs-nur, ... }: {
       nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
         modules = [
           fleurs-nur.nixosModules.openstarbound
           ./configuration.nix
         ];
       };
     };
   }
   ```

2. Or with NUR:
   ```nix
   { pkgs, ... }:
   {
     imports = [
       "${builtins.fetchTarball "https://github.com/ErodeesFleurs/fleurs-nur/archive/master.tar.gz"}/modules/openstarbound.nix"
     ];
   }
   ```

### Cannot Set Both Package and Path

If you see an assertion error about setting both `package` and `starboundAssetsPath`:

**Wrong**:
```nix
{
  programs.openstarbound = {
    enable = true;
    package = pkgs.openstarbound;
    starboundAssetsPath = "/custom/path";  # Error!
  };
}
```

**Correct** - Choose one approach:

Option 1 - Let the module build the package:
```nix
{
  programs.openstarbound = {
    enable = true;
    starboundAssetsPath = "/custom/path";
  };
}
```

Option 2 - Provide your own package:
```nix
{
  programs.openstarbound = {
    enable = true;
    package = pkgs.openstarbound.override {
      starboundAssetsPath = "/custom/path";
    };
  };
}
```

### Assets Not Found

If the game can't find assets after configuration:

1. Verify the path is correct:
   ```bash
   ls "$HOME/.local/share/Steam/steamapps/common/Starbound/assets"
   ```

2. Check your configuration:
   ```bash
   nixos-option programs.openstarbound.starboundAssetsPath
   ```

3. Rebuild with verbose output:
   ```bash
   sudo nixos-rebuild switch --show-trace
   ```

## Advanced Usage

### Conditional Configuration

Enable based on hostname:

```nix
{
  programs.openstarbound = {
    enable = (config.networking.hostName == "gaming-pc");
    starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
  };
}
```

### User-Specific Paths

Using mkIf for different users:

```nix
{ config, lib, ... }:

{
  programs.openstarbound = {
    enable = true;
    starboundAssetsPath = 
      if config.users.users.alice.isNormalUser
      then "/home/alice/.local/share/Steam/steamapps/common/Starbound/assets"
      else "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
  };
}
```

### Multiple Configurations Per Machine

For multi-user setups, each user can override:

```nix
# System configuration
{
  programs.openstarbound.enable = true;
  # Uses defaults
}

# Then users can override with environment variables:
# export STARBOUND_ASSETS="/custom/path"
```

## Migration Guide

### From Manual Installation

If you previously installed OpenStarbound manually:

**Before**:
```nix
{
  environment.systemPackages = [ pkgs.openstarbound ];
}
```

**After**:
```nix
{
  programs.openstarbound.enable = true;
}
```

### From Environment Variables

If you were using environment variables:

**Before**:
```nix
{
  environment.systemPackages = [ pkgs.openstarbound ];
  environment.sessionVariables = {
    STARBOUND_ASSETS = "/custom/path";
  };
}
```

**After**:
```nix
{
  programs.openstarbound = {
    enable = true;
    starboundAssetsPath = "/custom/path";
  };
}
```

## See Also

- [OpenStarbound Package Documentation](../pkgs/openstarbound/README.md)
- [Configuration Examples](../examples/openstarbound-custom-paths.nix)
- [OpenStarbound Upstream](https://github.com/OpenStarbound/OpenStarbound)
- [NixOS Module System](https://nixos.org/manual/nixos/stable/index.html#sec-writing-modules)