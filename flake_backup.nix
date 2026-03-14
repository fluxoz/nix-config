{
  description = "John's NixOS Config";

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    nixvim = {
      url = "github:nix-community/nixvim/nixos-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          inputs.nixvim.homeManagerModules.nixvim
          ./hardware-configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.users.john = import ./home.nix;
          }
          ({ config, lib, pkgs, ... }: {

        # ==== BOOT ==== 
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        boot.initrd.luks.devices."luks-2d406786-24e7-4317-8bb2-2b78bb9a9931".device = "/dev/disk/by-uuid/2d406786-24e7-4317-8bb2-2b78bb9a9931";

        # ==== NETWORK ====
          networking.hostName = "nixos"; 
          networking.networkmanager.enable = true;
          hardware.bluetooth.enable = true; # enables support for Bluetooth
          hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

        # ==== NIX FLAKES ====
          nix.settings.experimental-features = [ "nix-command" "flakes" ];

        # ==== UNFREE PACKAGES ====
          nixpkgs.config.allowUnfree = true;

        # ==== TIMEZONE ====
          time.timeZone = "America/Los_Angeles";

        # ==== LOCALE ====
          i18n.defaultLocale = "en_US.UTF-8";
          i18n.extraLocaleSettings = {
            LC_ADDRESS = "en_US.UTF-8";
            LC_IDENTIFICATION = "en_US.UTF-8";
            LC_MEASUREMENT = "en_US.UTF-8";
            LC_MONETARY = "en_US.UTF-8";
            LC_NAME = "en_US.UTF-8";
            LC_NUMERIC = "en_US.UTF-8";
            LC_PAPER = "en_US.UTF-8";
            LC_TELEPHONE = "en_US.UTF-8";
            LC_TIME = "en_US.UTF-8";
          };

        # ==== X11 ====
          services.xserver.enable = true;
          services.xserver = {
            xkb.layout = "us";
            xkb.variant = "";
          };

        # ==== AUDIO ====
          sound.enable = true;
          hardware.pulseaudio.enable = false;
          security.rtkit.enable = true;
          services.pipewire = {
            enable = true;
            alsa.enable = true;
            alsa.support32Bit = true;
            pulse.enable = true;
          };

        # ==== KDE ====
          services.displayManager.sddm.enable = true;
          services.xserver.desktopManager.plasma5.enable = true;

        # ==== FONTS ====
          fonts.packages = with pkgs; [
            (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" "FiraCode" "DroidSansMono" ]; })
            cantarell-fonts
            fira-code
            fira-code-symbols
          ];

        # ==== OPENGL ==== 
        hardware.opengl = {
          enable = true;
          driSupport = true;
          driSupport32Bit = true;
        };

        # ==== NVIDIA ====
          services.xserver.videoDrivers = ["nvidia"];
          hardware.nvidia = {
            modesetting.enable = true;
            powerManagement.enable = false;
            powerManagement.finegrained = false;
            open = false;
            nvidiaSettings = true;
            package = config.boot.kernelPackages.nvidiaPackages.stable;
          }; 

        # ==== UDEV ====
          services.udev.extraRules = ''
          ${builtins.readFile ./udev/50-zsa.rules}
          ${builtins.readFile ./udev/50-stm.rules}
          ${builtins.readFile ./udev/69-probe-rs.rules}
          '';

        # ==== CUPS ====
          services.printing.enable = true;

        # ==== USERS ====
          users.users.john = {
            isNormalUser = true;
            description = "john";
            extraGroups = [ "networkmanager" "wheel" "docker" "plugdev" ];
          };

        # ==== BASH ====
          programs.bash = {
            interactiveShellInit = ''eval "$(direnv hook bash)"'';
            shellAliases = {
              vim = "nvim";
            };
          }; 

        # ==== VIRTUALIZATION ====
          virtualisation.docker.enable = true;


        # ==== GROUPS ====
          users.groups.plugdev = {
            gid = 132;
          };

        # ==== SYSTEM PACKAGES ====
          environment.systemPackages = with pkgs; [
            gcc
            direnv
            docker
            docker-compose
            xclip
          ];

        # ==== SYSTEM STATE VERSION ====
        # This value determines the NixOS release from which the default
        # settings for stateful data, like file locations and database versions
        # on your system were taken. It‘s perfectly fine and recommended to leave
        # this value at the release version of the first install of this system.
        # Before changing this value read the documentation for this option
        # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
        system.stateVersion = "23.11"; # Did you read the comment?

      }) 
    ];
  };
};
  }; 
}
