{ config, ... }:

{
  # nh: nix helper CLI
  programs.nh = {
    enable = true;
    # Disable auto-clean until upstream gives nh-clean.service a Nix-aware PATH.
    clean.enable = false;
    # launchd passes a string as one argument; use a list.
    clean.extraArgs = [
      "--keep-since"
      "7d"
      "--keep"
      "3"
    ];
    homeFlake = "${config.home.homeDirectory}/.config/home-manager";
  };
}
