{ ... }:

let
  onePasswordPath = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
in

{
  imports = [
    ./default.nix
    # ./apps/ghostty.nix # ! ghostty-1.0.1 is marked as broken
  ];

  programs.git = {
    extraConfig = {
      core = {
        sshCommand = "ssh.exe";
      };
      commit = {
        gpgsign = true;
      };
    };
  };

  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host *
          IdentityAgent ${onePasswordPath}
    '';
  };

  home.homeDirectory = "/Users/snake575";

  home.sessionVariables = {
    SSH_AUTH_SOCK = "${onePasswordPath}";
  };

  # home.packages = with pkgs; [
  #   openjdk
  # ];
}
