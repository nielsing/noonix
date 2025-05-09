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
      nixboot = "sudo nixos-rebuild boot --flake ~/.config/noonix/#noonix";
      nixtest = "sudo nixos-rebuild test --flake ~/.config/noonix/#noonix";
      nixsearch = "nix search nixpkgs '\\.$1\$'";
      docker = "sudo docker";
      cat = "bat";
      catc = "bat -pp";
      rg = "rg --colors=match:fg:blue";
      hs = "history | rg $1";
      md = "mkdir";
      tml = "tmux ls";
      tma = "tmux attach -t";
      tms = "tmux new -s";
      k = "kubectl";
      uvr = "uv run";
      # Git based aliases
      g = "git";
      ga = "git add";
      gd = "git diff";
      gs = "git status";
      gc = "git checkout";
      gcb = "git checkout -b";
      gcm = "git checkout -b";
      gpl = "git pull origin $(git_current_branch)";
      gpu = "git push origin $(git_current_branch)";
      gac = "git add . && git commit -m";
    };

    initExtra = ''
      # Make bat handle -h and --help flags. Makes it more readable and enables paging
      alias -g -- -h='-h 2>&1 | bat --language=help --style=plain'
      alias -g -- --help='--help 2>&1 | bat --language=help --style=plain'

      cdd() {
        mkdir $1 && cd $_
      }

      obs() {
        cd ~/docs/vaults && nvim knowitall/index.md && cd -
      }

      gacp() {
        git add . && git commit -m $1 && git push origin $(git_current_branch)
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
