{ pkgs, ... }:

{
  imports = [
    ./default.nix
    # ./apps/ghostty.nix # ! ghostty-1.1.3 is marked as broken
  ];

  programs.git = {
    extraConfig = {
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
    extraConfig = ''
      IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    '';
  };

  home.homeDirectory = "/Users/snake575";

  programs.zsh.initContent = ''
    export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
  '';

  home.packages = with pkgs; [
    wget
  ];
}
