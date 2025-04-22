{
  config,
  pkgs,
  ...
}: {
  programs.password-store = {
    enable = true;
    settings = {
      PASSWORD_STORE_DIR = "/home/nielsing/.password-store/";
      PASSWORD_STORE_KEY = "E78A728DADEC09984B21AA6AB1EFF0C773DA8953";
      PASSWORD_STORE_CLIPTIME = "15";
    };
  };
}
