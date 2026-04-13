{ pkgs, ... }@inputs:
{

  ####configuration de base####

  # on active systemd-boot (on pourrai aussi utiliser grub)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # le nom d'hôte
  networking.hostName = "nixos";

  # on installe networkmanager pour faciliter la config réseau
  networking.networkmanager.enable = true;

  # information de timezone
  time.timeZone = "America/Toronto";

  # localisation
  i18n.defaultLocale = "en_CA.UTF-8";

  # on utilise le serveur x pour gérer le layout du clavier
  services.xserver.xkb = {
    layout = "ca";
    variant = "multix";
  };

  # option pour la console
  console.keyMap = "cf";

  ####configuration de l'utilisateur prinicpal####

  users.users = {
    emile = {
      extraGroups = [
        "wheel"
      ];
      
      isNormalUser = true;
      description = "utilisateur prinicipal pour le projet de veille";
      # d'autre options sont possible bien sûr. mais elle ne sont pas
      # nécéssaires ici, on les laisse par défaut.

      # le mot de passe de l'utilisateur, encrypté bien sûr
      hashedPassword = "$y$j9T$4T2a4YOIrrhNqvFOfy2Gu.$5mCWgf8amYgt9Hrv/UBo5CryT/gJ.oRQbX089gvpj1.";
      # (c'est Soleil01)
      # vous pouvez générer un nouveau mot de passe avec la commande mkpasswd

      packages = with pkgs; [
        # c'est ici que l'on spécifie les programme que l'on
        # veut installer pour notre utilisateur. il est le
        # seul qui aura accès à ces programmes.
        # par exemple:
        helix # un éditeur de texte que j'aime beaucoup
        fastfetch # un classique
        yazi # un explorateur de fichier dans le terminal
      ];
    };
  };

  # les packages ici seront installé pour tous les
  # utilisateurs, incluant root
  environment.systemPackages = with pkgs; [
    git
  ];

  
    #zsh settings and packages
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        # y = "yazi";
        ll = "lsd -l";
        la = "lsd -a";
        # lss = "ls -sh";
        cleanup = "nix-collect-garbage --delete-older-than 10d";
        ls = "lsd";
        cat = "bat";
        shin = "nix develop -c zsh";
      };
      # shellInit = "export PATH=$PATH:/home/lemox/.localbin";
      shellInit = ''
        eval "$(zoxide init zsh --cmd cd)"

        function y() {
        	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        	yazi "$@" --cwd-file="$tmp"
        	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        		builtin cd -- "$cwd"
        	fi
        	rm -f -- "$tmp"
        }

        function ns() {
          declare -A array
          for arg in "$@"; do
            array+=" nixpkgs#$arg"
          done
          nix shell "$array"
        }
      '';

      interactiveShellInit =
        let
          plugins = with pkgs; [
            "${zsh-autopair}/share/zsh/zsh-autopair/autopair.zsh"
            # "${zsh-helix-mode}/zsh-helix-mode.plugin.zsh"  # doesn't work yet
          ];

          source = map (path: "source ${path}") plugins;
          string = builtins.concatStringsSep "\n" source;
        in
        ''
          ${string}  
        '';

      ohMyZsh = {
        enable = true;
        theme = "murilasso";
        plugins = [
          #these are just autocomplete plugins not actual commands
          "git" # git cli
        ];
      };
    };

  ####configuration des services####

  services = {
    # c'est ici qu'on configure les services de notre serveur

    # un serveur ssh plus ou moins sécurisé
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        AllowUsers = [ "emile" ];
        PasswordAuthentication = true;
      };
    };

  };
  
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.auto-optimise-store = true;

  # on ouvre les ports du serveur ssh et http
  networking.firewall.allowedTCPPorts = [
    22
  ];

  # version initiale du système NE PAS TOUCHER
  system.stateVersion = "25.05";
}
