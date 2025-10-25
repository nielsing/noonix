{...}: {
  programs.git = {
    enable = true;
    settings = {
      pull.rebase = false;
      user = {
        email = "niels.ingi@gmail.com";
        name = "nielsing";
      };
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
        "git@github.com:" = {
          insteadOf = "gh:";
        };
      };
    };
  };
}
