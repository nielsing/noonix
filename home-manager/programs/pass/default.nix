{
  config,
  pkgs,
  ...
}: {
  programs.password-store = {
    enable = true;
    settings = {
      PASSWORD_STORE_DIR = "/home/nielsing/.password-store/";
      PASSWORD_STORE_KEY = "3663C1BE14AE56BA";
      PASSWORD_STORE_CLIPTIME = "15";
    };
  };
}
