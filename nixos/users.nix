{pkgs, ...}: {
  programs.adb.enable = true;
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
  users.users.nielsing = {
    isNormalUser = true;
    description = "nielsing";
    extraGroups = ["audio" "adbusers" "networkmanager" "wheel"];
    packages = with pkgs; [];
  };
}
