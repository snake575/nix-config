{ ... }:

{
  # lsd: modern ls replacement with colors and icons
  programs.lsd = {
    enable = true;
    enableBashIntegration = false;
    enableZshIntegration = true;
  };
}
