{
  description = "Custom NixOS installer with SSH and root login";

  outputs = { self, nixpkgs }: {
    iso = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          config = {
            # Basic ISO setup
            system.build.isoImage = nixpkgs.lib.nixosSystem.isoImage;

            # Enable SSH
            services.openssh = {
              enable = true;
              permitRootLogin = "yes"; # Allow root login
              passwordAuthentication = true; # Enable password-based auth
            };

            # Set the root password (replace 'root' with a secure password)
            users.users.root = {
              initialPassword = "root";
            };

            # Configure networking (set to DHCP for ISO)
            networking.networkmanager.enable = true;
          };
        }
      ];
    };
  };
}

