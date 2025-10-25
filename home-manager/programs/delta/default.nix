{...}: {
  programs.delta = {
    enable = true;
    options = {
      navigate = true;
      line-numbers = true;
      hyperlinks = true;
    };
    enableGitIntegration = true;
  };
}
