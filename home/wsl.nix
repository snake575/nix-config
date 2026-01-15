{ lib, ... }:

{
  # WSL-specific configuration
  # Uses Windows SSH and 1Password for seamless key management
  imports = [ ./linux.nix ];

  programs.git = {
    settings = {
      core = {
        # Use Windows SSH to share keys with Windows host
        sshCommand = "ssh.exe";
      };
      gpg = {
        # 1Password SSH signing agent (WSL path)
        ssh.program = "/mnt/c/Program Files/1Password/app/8/op-ssh-sign-wsl";
      };
    };
  };

  # Use Windows SSH tools to share agent with Windows host
  # Use lib.mkAfter to merge with base aliases instead of replacing them
  home.shellAliases = lib.mkAfter {
    ssh = "ssh.exe";
    ssh-add = "ssh-add.exe";
  };
}
