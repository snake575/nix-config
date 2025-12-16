{ pkgs, ... }:

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
    matchBlocks."*" = {
      host = "*";
      identityAgent = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    };
  };

  home.sessionVariables = {
    # Point SSH_AUTH_SOCK to 1Password agent
    SSH_AUTH_SOCK = "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  };

  # macOS-specific packages
  home.packages = with pkgs; [
    wget # not included by default on macOS
  ];
}
