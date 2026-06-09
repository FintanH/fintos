{
  description = "NixOS: fintohaps";

  inputs = {
    # Official NixOS package source
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";

    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://cache.numtide.com"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nur,
    microvm,
    sops-nix,
    ...
  } @ inputs: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
    };
    unstable = import inputs.nixpkgs-unstable {system = "x86_64-linux";};
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
    nixosConfigurations = {
      # To deploy this NixOS system (from any directory):
      #   sudo nixos-rebuild switch --flake fintos
      "haptop" = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs nurNoPkgs;};
        modules =
          [
            ./configuration.nix
            ./modules/nixos/gnome.nix
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
            {
              nixpkgs.overlays = [
                (import ./overlays/radicle-node.nix)
                (import ./overlays/pi-packages.nix)
              ];
            }
            microvm.nixosModules.host
            ./microvm/network.nix
            ./microvm.nix
          ]
          ++ registryModule;
      };
    };
  };
}
