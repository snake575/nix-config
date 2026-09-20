{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    # ./apps/bash.nix
    ./apps/zsh.nix
    ./apps/git.nix
    ./apps/gh.nix
    ./apps/direnv.nix
    ./apps/bun.nix
    ./apps/btop.nix
    ./apps/lsd.nix
    ./apps/poetry.nix
    ./apps/nh.nix
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.pnpm = {
    enable = true;
    # Avoid moving existing macOS globals to the module's ~/Library/pnpm default.
    pnpmHome = "${config.home.homeDirectory}/.local/share/pnpm";
  };

  home.username = "snake575";
  home.homeDirectory = lib.mkDefault "/home/snake575";

  home.packages = with pkgs; [
    # System
    fastfetch
    _7zz
    dnsutils

    # Development
    nodejs_24
    python3
    go
    libpqxx

    # Tools
    ripgrep
    fd
    jq
    yq
    gopls
    nixd
    nixfmt
  ];

  # BUN_INSTALL sets the root directory for bun global packages (~/.bun)
  # Required for global installs to work on NixOS since the store is read-only
  home.sessionVariables = {
    BUN_INSTALL = "$HOME/.bun";
  };

  home.sessionPath = [
    "$HOME/.bun/bin" # bun global packages
    "$HOME/.local/share/pnpm" # legacy pnpm global binaries
    "$HOME/.local/bin" # user-local binaries (e.g. Claude Code installer)
  ];

  home.shellAliases = {
    nix-clean = "nix-collect-garbage -d";
  };

  # https://nix-community.github.io/home-manager/usage/upgrading.html
  home.stateVersion = "26.05";
}
