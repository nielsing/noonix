{
  pkgs,
  ...
}: {
  fonts = {
    packages = with pkgs; [
      roboto
      dejavu_fonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      (nerdfonts.override {fonts = ["JetBrainsMono"];})
    ];
    fontconfig = {
      defaultFonts = {
        monospace = ["JetBrainsMono Nerd Font" "Noto Color Emoji"];
        sansSerif = ["Roboto" "Noto Color Emoji"];
        serif = ["Roboto" "Noto Color Emoji"];
        emoji = ["Noto Color Emoji"];
      };
    };
  };
}
