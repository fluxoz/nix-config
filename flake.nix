{ 
  description = "Fluxoz's NixOS Config";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixvim = {
      url = "github:fluxoz/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    secrets = {
      url = "git+ssh://git@github.com/fluxoz/nix-secrets.git?shallow=1";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
    nixos-apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    starfin = {
      url = "git+ssh://git@github.com/fluxoz/starfin.git";
    };
    zeroclaw = {
      url = "github:fluxoz/zeroclaw";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixvim, nixos-apple-silicon, home-manager, disko, sops-nix, secrets, starfin, zeroclaw, ... }:
  let
    secrets-file = "${secrets}/secrets.yaml";
  in {
    # enable cache for niri to prevent building from source
    # niri-flake.cache.enable = true;
    nixosConfigurations = {
      tower = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit self;
          inherit nixvim;
          inherit (nixpkgs) lib;
          homeManagerModule = home-manager.nixosModules.home-manager;
        };
        system = "x86_64-linux";
        modules = [ 
          {
            home-manager.desktopUser = true;
          }
          ./hosts/tower
          sops-nix.nixosModules.sops
          { sops.defaultSopsFile = secrets-file; }
        ];
      };

      mini = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit self;
          inherit nixvim;
          homeManagerModule = home-manager.nixosModules.home-manager;
        };
        system = "aarch64-linux";
        modules = [
          {
            home-manager.desktopUser = false;
          }
          ./hosts/mini          
          nixos-apple-silicon.nixosModules.default
          # zeroclaw.nixosModules.zeroclaw
          sops-nix.nixosModules.sops
          { sops.defaultSopsFile = secrets-file; }
        ];
      };

      nuc = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit self;
          inherit disko;
          inherit nixvim;
          inherit (nixpkgs) lib;
          homeManagerModule = home-manager.nixosModules.home-manager;
        };
        system = "x86_64-linux";
        modules = [
          {
            home-manager.desktopUser = false;
          }
          disko.nixosModules.disko
          ./hosts/nuc          
          sops-nix.nixosModules.sops
          { sops.defaultSopsFile = secrets-file; }
          { _module.args.backup-key = "${secrets}/storage.backup.key"; }
          { _module.args.photos-key = "${secrets}/storage.photos.key"; }
          { _module.args.jellyfin-key = "${secrets}/storage.jellyfin.key"; }
          { _module.args.lan-key = "${secrets}/lan.key"; }
          starfin.nixosModules.default
        ];
      };

      server = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit self;
          inherit disko;
          inherit nixvim;
          inherit (nixpkgs) lib;
          homeManagerModule = home-manager.nixosModules.home-manager;
        };
        system = "x86_64-linux";
        modules = [
          {
            home-manager.desktopUser = false;
          }
          disko.nixosModules.disko
          ./hosts/server          
          sops-nix.nixosModules.sops
          { sops.defaultSopsFile = secrets-file; }
        ];
      };
    };
  };
}
