{
  programs.git = {
    enable = true;

    userEmail = "sarang575@gmail.com";
    userName = "Sebastian Aranguiz";

    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBw3EL4OczY1V0EpcA1UUE8ovsDbf1WS3TOQvFsGH+1G";
      signByDefault = true;
    };

    extraConfig = {
      core = {
        autocrlf = "input";
        filemode = false;
        eol = "lf";
        sshCommand = "ssh.exe";
      };

      gpg = {
        format = "ssh";
        ssh.program = "/mnt/c/Program Files/1Password/app/8/op-ssh-sign-wsl";
      };

      push = {
        default = "simple";
        autoSetupRemote = true;
      };

      init = {
        defaultBranch = "main";
      };
    };

    delta = {
      enable = true;
      options = {
        line-numbers = true;
      };
    };

    aliases = {
      undo = "reset --soft HEAD^";
    };

  };
}
