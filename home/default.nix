{ pkgs, lib, ... }:

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

  home.username = "snake575";
  home.homeDirectory = lib.mkDefault "/home/snake575";

  home.packages = with pkgs; [
    # System
    neofetch
    _7zz
    dnsutils

    # Development
    nodejs_24
    pnpm
    python3
    libpqxx

    # Tools
    claude-code
    nixd
    nixfmt-rfc-style
  ];

  home.shellAliases = {
    nix-clean = "nix-collect-garbage -d";
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  # https://nixos.org/manual/nixos/unstable/release-notes.html
  home.stateVersion = "25.11";
}
