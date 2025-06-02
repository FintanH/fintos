{
  description = "NixOS: fintohaps";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nur,
    ...
  } @ inputs: let
    pkgs = import nixpkgs {system = "x86_64-linux";};
    unstable = import inputs.unstable-pkgs {system = "x86_64-linux";};
    nurNoPkgs = import nur {nurpkgs = pkgs;};
    registryModule = [
      {
        nix.registry.nixpkgs.flake = inputs.nixpkgs;
        # register this flake in the registry so we can refer to it as
        # fintos
        nix.registry.fintos.flake = inputs.self;
      }
    ];
  in {
    # Formatter
    formatter.x86_64-linux = pkgs.alejandra;
    # Fonts
    fonts.fonts = with pkgs; [
      dejavu-sans
      fantasque-sans-mono
      fira-code
      fira-code-symbols
      liberation_ttf
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
    ];

    nixosConfigurations = {
      # To deploy this NixOS system (from any directory):
      #   sudo nixos-rebuild switch --flake fintos
      "haptop" = nixpkgs.lib.nixosSystem {
        modules =
          [
            ./configuration.nix
            ./home/gnome.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.fintohaps = ./home.nix;

              # Optionally, use home-manager.extraSpecialArgs to pass
              # arguments to home.nix
              home-manager.extraSpecialArgs = {
                inherit nurNoPkgs;
                inherit unstable;
                inherit inputs;
              };
            }
          ]
          ++ registryModule;
      };
    };
  };

  inputs = {
    # Official NixOS package source
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";

    unstable-pkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";

    radicle = {
      # Use for pinning to a tag
      url = "git+https://seed.radicle.xyz/z3gqcJUoA1n9HaHKufZs5FCSGazv5.git?ref=refs/namespaces/z6MkireRatUThvd3qzfKht1S44wpm4FEWSSa4PRMTSQZ3voM/refs/tags/v1.2.0";

      # Use for pinning to a particular revision/commit
      # url = "git+https://seed.radicle.xyz/z3gqcJUoA1n9HaHKufZs5FCSGazv5.git?rev=17139b7e56d5f6e80c1b675873289cd5c08c4823";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    radicle-desktop = {
      url = "git+https://seed.radicle.xyz/z4D5UCArafTzTQpDZNQRuqswh3ury.git?rev=da4bbe2fc136918903e20d01f7a1893a4732462c";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Cannot be found?
    # radicle-tui = {
    #   url = "git+https://seed.radicle.xyz/z39mP9rQAaGmERfUMPULfPUi473tY.git?ref=refs/namespaces/z6MkgFq6z5fkF2hioLLSNu1zP2qEL1aHXHZzGH1FLFGAnBGz/refs/tags/0.6.0";
    # };
  };
}
