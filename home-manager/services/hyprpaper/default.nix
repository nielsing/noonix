{...}: {
  services.hyprpaper = {
    enable = true;
    settings = {
      splash = false;
      wallpaper = [
        {
          monitor = "";
          path = "~/pics/ambaga-bg.jpg";
        }
      ];
    };
  };
}
