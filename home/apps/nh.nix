{ config, ... }:

{
  # nh: nix helper CLI
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 7d --keep 3";
    homeFlake = "${config.home.homeDirectory}/.config/home-manager";
  };
}
