{ ... }:

{
  imports = [ ./default.nix ];

  targets.genericLinux.enable = true;
  # This VM is permanently headless, so it does not need host GPU driver integration.
  targets.genericLinux.gpu.enable = false;

  home.sessionPath = [
    "/home/linuxbrew/.linuxbrew/bin"
    "/home/linuxbrew/.linuxbrew/sbin"
  ];
}
