{...}: {
  programs.git = {
    enable = true;
    userEmail = "niels.ingi@gmail.com";
    userName = "nielsing";
    delta = {
      enable = true;
      options = {
        navigate = true;
        line-numbers = true;
        hyperlinks = true;
      };
    };
    extraConfig = {
      url = {
        "git@github.com:ambagasec/" = {
          insteadOf = "ambaga:";
        };
        "git@github.com:nielsing/" = {
          insteadOf = "nielsing:";
        };
        "git@github.com:gagnaglimufelag-islands/" = {
          insteadOf = "ggfi:";
        };
        "git@github.com" = {
          insteadOf = "gh:";
        };
      };
    };
  };
}
