{ ... }:

{
  # direnv: auto-load environment when entering directories
  programs.direnv = {
    enable = true;
    enableBashIntegration = false;
    enableZshIntegration = true;
    nix-direnv.enable = true; # faster nix shell caching
    config.global = {
      load_dotenv = true; # auto-load .env files
      hide_env_diff = true; # cleaner output
      log_format = "-"; # hide status logging; errors still print (direnv 2.38+)
    };
  };
}
