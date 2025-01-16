{
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "code";
      pager = "delta --line-numbers";
    };
  };
}
