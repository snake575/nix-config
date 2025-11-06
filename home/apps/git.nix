{
  programs.git = {
    enable = true;

    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBw3EL4OczY1V0EpcA1UUE8ovsDbf1WS3TOQvFsGH+1G";
      signByDefault = true;
    };

    settings = {
      user = {
        email = "sarang575@gmail.com";
        name = "Sebastian Aranguiz";
      };

      core = {
        autocrlf = "input";
        filemode = false;
        eol = "lf";
      };

      gpg = {
        format = "ssh";
      };

      push = {
        default = "simple";
        autoSetupRemote = true;
      };

      init = {
        defaultBranch = "main";
      };

      alias = {
        undo = "reset --soft HEAD^";
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      line-numbers = true;
    };
  };
}
