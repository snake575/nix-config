{ pkgs, lib, ... }:

let
  homebrewPrefix = "/opt/homebrew";
in
{
  # macOS-specific configuration
  imports = [
    ./default.nix
    # ./apps/ghostty.nix # ! ghostty-1.1.3 is broken, re-enable when fixed
  ];

  home.homeDirectory = "/Users/snake575";

  # 1Password SSH agent integration
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false; # don't apply default ssh_config values
    settings."*" = {
      # Needs quoting because the path contains a space ("Group Containers").
      IdentityAgent = ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';
    };
  };

  home.sessionVariables = {
    # Point SSH_AUTH_SOCK to 1Password agent
    SSH_AUTH_SOCK = "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    # Homebrew installed outside Nix
    HOMEBREW_PREFIX = homebrewPrefix;
    HOMEBREW_CELLAR = "${homebrewPrefix}/Cellar";
    HOMEBREW_REPOSITORY = homebrewPrefix;
    INFOPATH = "${homebrewPrefix}/share/info:$INFOPATH";
  };

  home.sessionPath = lib.mkBefore [
    "${homebrewPrefix}/bin"
    "${homebrewPrefix}/sbin"
  ];

  programs.zsh.profileExtra = ''
    # OrbStack shell integration
    source ~/.orbstack/shell/init.zsh 2>/dev/null || :
  '';

  # macOS-specific packages
  home.packages = with pkgs; [
    wget # not included by default on macOS
  ];
}
