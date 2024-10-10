{ ... }:
{
  imports = [
    ./default.nix
  ];

  targets.genericLinux.enable = true;

  programs.git = {
    extraConfig = {
      core = {
        sshCommand = "ssh.exe";
      };
      gpg = {
        ssh.program = "/mnt/c/Program Files/1Password/app/8/op-ssh-sign-wsl";
      };
    };
  };
}
