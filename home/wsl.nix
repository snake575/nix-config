{ ... }:

{
  imports = [
    ./linux.nix
  ];

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

  home.shellAliases = {
    ssh = "ssh.exe";
    ssh-add = "ssh-add.exe";
  };
}
