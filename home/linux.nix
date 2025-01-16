{ ... }:

{
  imports = [
    ./default.nix
  ];

  targets.genericLinux.enable = true;

  home.homeDirectory = "/home/snake575";
}
