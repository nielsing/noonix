{
  config,
  pkgs,
  ...
}: {
  programs.zsh = {
    enable = true;

    history = {
      ignoreSpace = true;
      save = 10000;
      size = 10000;
      share = true;
    };

    oh-my-zsh = {
      enable = true;
    };

    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting = {
      enable = true;
    };

    shellAliases = {
      nixswitch = "sudo nixos-rebuild switch --flake ~/.config/noonix/#noonix";
      nixsearch = "nix search nixpkgs '\\.$1\$'";
      cat = "bat";
      catc = "bat -pp";
      rg = "rg --colors=match:fg:blue";
      hsts = "history | rg $1";
      md = "mkdir";
      tml = "tmux ls";
      tma = "tmux attach -t";
      tms = "tmux new -s";
      k = "kubectl";
      uvr = "uv run";
    };

    initExtra = ''
      # Make bat handle -h and --help flags. Makes it more readable and enables paging
      alias -g -- -h='-h 2>&1 | bat --language=help --style=plain'
      alias -g -- --help='--help 2>&1 | bat --language=help --style=plain'

      cdd() {
        mkdir $1 && cd $_
      }

      obs() {
        cd ~/src/vaults && nvim knowitall/index.md && cd -
      }
    '';

    envExtra = ''
      # Make bat manpager
      export MANPAGER="sh -c 'col -bx | bat -l man -p'"
      export MANROFFOPT="-c"
      export TERM=xterm-256color
    '';
  };
}
