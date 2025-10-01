{...}: {
  services.hyprsunset = {
    enable = true;
    settings = {
      max-gamma = 100;

      profile = [
        {
          time = "7:00";
          temperature = 6500;
          gamma = 1;
        }
        {
          time = "20:30";
          temperature = 3000;
          gamma = 0.5;
        }
      ];
    };
  };
}
