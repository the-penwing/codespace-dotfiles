# flake.nix for the Codespaces dotfiles repo.
{
  description = "Codespaces home-manager config, built from the-penwing/nixos-config";

  inputs = {
    nixos-config.url = "github:the-penwing/nixos-config";
    nixpkgs.follows = "nixos-config/nixpkgs";
    home-manager.follows = "nixos-config/home-manager";
  };

  outputs = {
    nixpkgs,
    home-manager,
    nixos-config,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    shellModule = name: import "${nixos-config}/modules/home/${name}";
  in {
    homeConfigurations.codespace = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        (shellModule "zsh.nix")
        (shellModule "starship.nix")
        (shellModule "atuin.nix")
        (shellModule "zoxide.nix")
        (shellModule "direnv.nix")
        (shellModule "fzf.nix")
        (shellModule "git.nix")
        (shellModule "fastfetch.nix")

        ({lib, ...}: {
          programs.git.settings.credential.helper = lib.mkForce "!gh auth git-credential";
          programs.fastfetch.settings.logo.source = lib.mkForce "auto";
          programs.bash = {
            enable = true;
            initExtra = ''
              if [[ $- == *i* ]] && command -v zsh >/dev/null 2>&1; then
                exec zsh
              fi
            '';
          };
        })

        {
          home.username = "codespace";
          home.homeDirectory = "/home/codespace";
          home.stateVersion = "25.11";

          home.sessionVariables.EDITOR = "nvim";

          home.packages = [
            # Shell
            pkgs.sesh

            # Search
            pkgs.fd
            pkgs.ripgrep
            pkgs.sd
            pkgs.jq

            # Files
            pkgs.bat
            pkgs.eza
            pkgs.dust
            pkgs.duf
            pkgs.file

            # Docs
            pkgs.tlrc

            # Monitor
            pkgs.btop

            # Build
            pkgs.just
            pkgs.gnumake
            pkgs.hyperfine

            # Network
            pkgs.curl
            pkgs.wget

            # Nix
            pkgs.nil
            pkgs.nixd
            pkgs.alejandra
            pkgs.nix-search-tv

            # Editor
            pkgs.neovim
            pkgs.tree-sitter

            # Security
            pkgs.gnupg

            # Terminal Toy
            pkgs.fetch
          ];
        }
      ];
    };
  };
}
