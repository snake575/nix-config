{ pkgs, ... }:

{
  imports = [
    ./default.nix
    # ./apps/ghostty.nix # ! ghostty-1.1.3 is marked as broken
  ];

  programs.git = {
    settings = {
      core = {
        sshCommand = "ssh";
      };
      commit = {
        gpgsign = true;
      };
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      host = "*";
      identityAgent = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    };
  };

  home.homeDirectory = "/Users/snake575";

  home.sessionVariables = {
    SSH_AUTH_SOCK = "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  };

  home.packages = with pkgs; [
    wget
  ];
}
