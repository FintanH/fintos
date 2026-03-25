{
  description = "NixOS: fintohaps";

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
      overlays = [
        (import ./overlays/radicle-node.nix)
        inputs.opencode.overlays.default
      ];
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
        specialArgs = {inherit inputs nurNoPkgs;};
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
            {
              nixpkgs.overlays = [
                (import ./overlays/radicle-node.nix)
              ];
            }
            microvm.nixosModules.host
            ./microvm/network.nix
            ./microvm/vm-home.nix
            ./microvm.nix
          ]
          ++ registryModule;
      };
    };
  };

  inputs = {
    # Official NixOS package source
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.11";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # home-manager, used for managing user configuration
    home-manager = {
      # url = "git+https://github.com/lorenzleutgeb/home-manager.git?rev=4a0213a852c4c8100b706cae04ea54dbe1e8f956";
      url = "github:nix-community/home-manager/release-25.11";
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
    opencode.url = "github:dan-online/opencode-nix";
    llm-agents.url = "github:numtide/llm-agents.nix";
  };
}
