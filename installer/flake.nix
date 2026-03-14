{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations = {
      isoimage = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ];
      };
    };
    packages."x86_64-linux".default = self.nixosConfigurations.isoimage.config.system.build.isoImage;
  };
}
