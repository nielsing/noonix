{
  config,
  pkgs,
  ...
}: {
  programs.git = {
    enable = true;
    userEmail = "niels.ingi@gmail.com";
    userName = "nielsing";
  };
}
