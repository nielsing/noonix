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
    transitions = {
      sunrise = {
        calendar = "*-*-* 06:00:00";
        requests = [
          ["temperature" "6500"]
          ["gamma 100"]
        ];
      };
      sunset = {
        calendar = "*-*-* 21:30:00";
        requests = [
          ["temperature" "3500"]
          ["gamma 50"]
        ];
      };
    };
  };
}
