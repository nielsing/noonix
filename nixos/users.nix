{pkgs, ...}: {
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
  users.users.nielsing = {
    isNormalUser = true;
    description = "nielsing";
    extraGroups = ["audio" "networkmanager" "wheel"];
    packages = with pkgs; [];
  };
}
