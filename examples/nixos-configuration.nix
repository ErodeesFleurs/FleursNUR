# Example NixOS configurations using the OpenStarbound module
#
# This file demonstrates various ways to configure OpenStarbound
# using the programs.openstarbound module.

{ ... }:

{
  # ============================================================================
  # Example 1: Basic Configuration (Recommended for most users)
  # ============================================================================

  programs.openstarbound = {
    enable = true;
    # Uses default paths:
    # - Assets: $HOME/.local/share/Steam/steamapps/common/Starbound/assets
    # - Storage: $HOME/.local/share/OpenStarbound/storage
    # - Logs: $HOME/.local/share/OpenStarbound/logs
    # - Mods: $HOME/.local/share/OpenStarbound/mods
  };

  # ============================================================================
  # Example 2: Flatpak Steam Configuration
  # ============================================================================

  # programs.openstarbound = {
  #   enable = true;
  #   starboundAssetsPath = "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Starbound/assets";
  # };

  # ============================================================================
  # Example 3: External Storage Configuration
  # ============================================================================

  # programs.openstarbound = {
  #   enable = true;
  #   starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
  #   storageDir = "/mnt/games/OpenStarbound/storage";
  #   logDir = "/mnt/games/OpenStarbound/logs";
  #   modDir = "/mnt/games/OpenStarbound/mods";
  # };

  # ============================================================================
  # Example 4: Multiple Asset Directories (Workshop + Custom Mods)
  # ============================================================================

  # programs.openstarbound = {
  #   enable = true;
  #   starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
  #   extraAssetDirs = [
  #     "$HOME/OpenStarbound/workshop-content"
  #     "$HOME/OpenStarbound/custom-assets"
  #     "/mnt/shared/starbound-community-mods"
  #   ];
  # };

  # ============================================================================
  # Example 5: Development Setup
  # ============================================================================

  # programs.openstarbound = {
  #   enable = true;
  #   starboundAssetsPath = "$HOME/.local/share/Steam/steamapps/common/Starbound/assets";
  #   storageDir = "$HOME/Development/starbound-test/saves";
  #   logDir = "$HOME/Development/starbound-test/logs";
  #   modDir = "$HOME/Development/starbound-test/mods";
  #   extraAssetDirs = [
  #     "$HOME/Development/starbound-test/test-assets"
  #   ];
  # };

  # ============================================================================
  # Example 6: Custom Package
  # ============================================================================

  # programs.openstarbound = {
  #   enable = true;
  #   package = pkgs.openstarbound.override {
  #     # Custom build options if needed
  #   };
  # };

  # ============================================================================
  # Example 7: Complete Gaming Setup with Steam
  # ============================================================================

  # Enable Steam for Starbound assets
  # programs.steam = {
  #   enable = true;
  #   remotePlay.openFirewall = true;
  # };

  # programs.openstarbound = {
  #   enable = true;
  #   # Automatically uses Steam's install location
  # };

  # Additional gaming optimizations
  # hardware.opengl = {
  #   enable = true;
  #   driSupport = true;
  #   driSupport32Bit = true;
  # };

  # ============================================================================
  # Example 8: Server Setup
  # ============================================================================

  # For a dedicated Starbound server setup
  # programs.openstarbound = {
  #   enable = true;
  #   starboundAssetsPath = "/srv/starbound/assets";
  #   storageDir = "/srv/starbound/storage";
  #   logDir = "/var/log/starbound";
  #   modDir = "/srv/starbound/mods";
  # };

  # Create necessary directories
  # systemd.tmpfiles.rules = [
  #   "d /srv/starbound 0755 starbound starbound -"
  #   "d /srv/starbound/assets 0755 starbound starbound -"
  #   "d /srv/starbound/storage 0755 starbound starbound -"
  #   "d /srv/starbound/mods 0755 starbound starbound -"
  #   "d /var/log/starbound 0755 starbound starbound -"
  # ];

  # ============================================================================
  # Example 9: Multi-User Setup
  # ============================================================================

  # Enable OpenStarbound for all users
  # programs.openstarbound.enable = true;

  # Users can override paths with environment variables:
  # export STARBOUND_ASSETS="/custom/path"
  # export XDG_DATA_HOME="$HOME/.local/share"

  # ============================================================================
  # Example 10: Conditional Configuration (Per-Machine)
  # ============================================================================

  # programs.openstarbound = {
  #   enable = (config.networking.hostName == "gaming-pc");
  #   starboundAssetsPath =
  #     if config.networking.hostName == "gaming-pc"
  #     then "$HOME/.local/share/Steam/steamapps/common/Starbound/assets"
  #     else "/mnt/network/steam/Starbound/assets";
  # };

  # ============================================================================
  # Additional Useful Configurations
  # ============================================================================

  # Allow unfree packages (required for some dependencies)
  # nixpkgs.config.allowUnfree = true;

  # Install useful gaming utilities
  # environment.systemPackages = with pkgs; [
  #   # Mod management tools
  #   # steamcmd
  #
  #   # Performance monitoring
  #   # mangohud
  #   # goverlay
  # ];

  # Enable gamemode for better performance
  # programs.gamemode.enable = true;

  # ============================================================================
  # Notes
  # ============================================================================

  # 1. You need to own and install Starbound (usually via Steam)
  # 2. Paths with $HOME are expanded at runtime for each user
  # 3. Rebuild your system after changes: sudo nixos-rebuild switch
  # 4. Launch from app menu or run: openstarbound
  # 5. Check logs if issues occur: ~/.local/share/OpenStarbound/logs/
}
