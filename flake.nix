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
    nurNoPkgs = import nur {nurpkgs = pkgs;};
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
      # To deploy this NixOS system:
      #   sudo nixos-rebuild switch --flake .#nixos-test
      "nixos-test" = nixpkgs.lib.nixosSystem {
        modules = [
          ./configuration.nix
          ./home/gnome.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.fintohaps = ./home.nix;

            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
            home-manager.extraSpecialArgs = {inherit nurNoPkgs; inherit inputs;};
          }
        ];
      };
    };
  };

  inputs = {
    # Official NixOS package source
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";

    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";

    radicle.url = "github:radicle-dev/heartwood/nix-flake";
  };
}
