{ ... }:

{
  imports = [ ./default.nix ];

  targets.genericLinux.enable = true;

  home.sessionPath = [
    "/home/linuxbrew/.linuxbrew/bin"
    "/home/linuxbrew/.linuxbrew/sbin"
  ];
}
