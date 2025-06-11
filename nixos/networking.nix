{
  networking.hostName = "loonix";
  networking.firewall.checkReversePath = "loose";
  networking.networkmanager.enable = true;
  services.avahi.enable = true;
}
