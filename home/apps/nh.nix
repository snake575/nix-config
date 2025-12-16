{ ... }:

{
  # nh: nix helper CLI
  programs.nh = {
    enable = false; # TODO: disabled pending nh fix for WSL PATH spaces (see issue https://github.com/nix-community/nh/issues/421)
    # keep config ready to re-enable once upstream fixes sudo/env PATH handling
    clean.enable = true;
    clean.extraArgs = "--keep-since 7d --keep 3";
    homeFlake = "/home/snake575/.config/home-manager";
  };
}
