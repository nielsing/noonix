{...}: {
  programs.vscode = {
    enable = true;
    profiles.default = {
      userSettings = {
        "editor.fontFamily" = "'JetBrainsMono NF'";
        "editor.fontLigatures" = true;
        "editor.fontSize" = 15;
        "editor.minimap.enabled" = false;
        "keyboard.dispatch" = "keyCode";
      };
    };
  };
}
