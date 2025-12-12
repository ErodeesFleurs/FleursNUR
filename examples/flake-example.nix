# Example flake.nix for using OpenStarbound with the NixOS module
#
# This demonstrates how to integrate fleurs-nur into your system flake
# and use the programs.openstarbound module.

{
  description = "My NixOS Configuration with OpenStarbound";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Add fleurs-nur as an input
    fleurs-nur = {
      url = "github:ErodeesFleurs/fleurs-nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Optional: home-manager for user-level configuration
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      fleurs-nur,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      # ========================================================================
      # Example 1: Basic NixOS Configuration
      # ========================================================================

      nixosConfigurations.my-desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Import the OpenStarbound module
          fleurs-nur.nixosModules.openstarbound

          # Your configuration
          {
            programs.openstarbound.enable = true;

            # Rest of your configuration...
          }
        ];
      };

      # ========================================================================
      # Example 2: With Custom Paths
      # ========================================================================

      nixosConfigurations.gaming-pc = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          fleurs-nur.nixosModules.openstarbound

          {
            programs.openstarbound = {
              enable = true;
              starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
              storageDir = "/mnt/games/OpenStarbound/storage";
              modDir = "/mnt/games/OpenStarbound/mods";
            };

            # Enable Steam for Starbound
            programs.steam.enable = true;
          }
        ];
      };

      # ========================================================================
      # Example 3: With Overlay (Alternative Method)
      # ========================================================================

      nixosConfigurations.with-overlay = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          {
            # Add fleurs-nur overlay to nixpkgs
            nixpkgs.overlays = [ fleurs-nur.overlays.default ];

            # Now you can use pkgs.openstarbound
            environment.systemPackages = [
              (pkgs.openstarbound.withPaths {
                starboundAssets = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
                storage = "$HOME/.local/share/OpenStarbound/storage";
                mods = "$HOME/.local/share/OpenStarbound/mods";
              })
            ];
          }
        ];
      };

      # ========================================================================
      # Example 4: With Home Manager
      # ========================================================================

      nixosConfigurations.with-home-manager = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          home-manager.nixosModules.home-manager
          fleurs-nur.nixosModules.openstarbound

          {
            # System-level configuration
            programs.openstarbound = {
              enable = true;
              starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
            };

            # Home-manager configuration
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.alice =
              { ... }:
              {
                # User-specific overrides
                home.file.".config/openstarbound/settings.json".text = ''
                  {
                    "customSettings": true
                  }
                '';
              };
          }
        ];
      };

      # ========================================================================
      # Example 5: Multiple Machines with Shared Configuration
      # ========================================================================

      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            fleurs-nur.nixosModules.openstarbound
            ./common.nix
            ./desktop.nix
          ];
        };

        laptop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            fleurs-nur.nixosModules.openstarbound
            ./common.nix
            ./laptop.nix
          ];
        };
      };

      # ========================================================================
      # Example 6: Development Shell
      # ========================================================================

      devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
        packages = [
          fleurs-nur.packages.x86_64-linux.openstarbound
        ];

        shellHook = ''
          echo "OpenStarbound development environment"
          echo "Run 'openstarbound' to start the game"
        '';
      };
    };
}

# ============================================================================
# Supporting Files
# ============================================================================

# --- common.nix ---
# Shared configuration for all machines
/*
  { config, pkgs, ... }:

  {
    programs.openstarbound = {
      enable = true;
      # Shared defaults
    };
  }
*/

# --- desktop.nix ---
# Desktop-specific configuration
/*
  { config, pkgs, ... }:

  {
    programs.openstarbound = {
      starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
      storageDir = "/mnt/games/OpenStarbound/storage";
    };
  }
*/

# --- laptop.nix ---
# Laptop-specific configuration
/*
  { config, pkgs, ... }:

  {
    programs.openstarbound = {
      starboundAssetsPath = "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Starbound/assets";
      # Use default XDG directories on laptop
    };
  }
*/

# ============================================================================
# Usage Instructions
# ============================================================================

# 1. Save this as flake.nix in your NixOS configuration directory
#
# 2. Add your actual configuration files (hardware-configuration.nix, etc.)
#
# 3. Build and switch:
#    sudo nixos-rebuild switch --flake .#my-desktop
#
# 4. The OpenStarbound module will:
#    - Install the package
#    - Configure paths
#    - Set up desktop integration
#
# 5. Launch the game:
#    - From application menu: Search "OpenStarbound"
#    - From terminal: openstarbound
#
# 6. Update the flake:
#    nix flake update
#    sudo nixos-rebuild switch --flake .#my-desktop

# ============================================================================
# Tips
# ============================================================================

# - Use 'nix flake show' to see available outputs
# - Use 'nixos-option programs.openstarbound' to check current config
# - Set 'programs.openstarbound.enable = true;' for simple setup
# - Customize paths for advanced setups
# - Check logs at ~/.local/share/OpenStarbound/logs/ if issues occur
