{ self, config, pkgs, niri, ... }:
{
  imports = [ 
    ../../shared/home-manager/home-manager.nix
    ./hardware-configuration.nix
    ../common/core
    ../common/optional/bluetooth.nix
    ../common/optional/xbox-controller.nix
    ../common/optional/desktop-environments/plasma.nix
    # ../common/optional/desktop-environments/niri.nix
    ../common/optional/audio.nix
    ../common/optional/fonts.nix
    ../common/optional/nvidia.nix
    ../common/optional/x11.nix
    ../common/optional/tailscale.nix
    ../common/optional/vmware.nix
    ../common/optional/podman.nix
    ../common/optional/local_ca.nix
  ];

  sops = {
    secrets = {
      "passwords/tower/murphy" = {
        neededForUsers = true;
      };
    };
  };

  # ==== BOOT ==== 
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Install EDID as firmware-like data
  environment.etc."firmware/edid/lg-tv.bin".source = ./hardware/edid/lg-tv.bin;

  boot.kernelParams = [
    # Feed the EDID to that exact connector
    "drm.edid_firmware=HDMI-A-3:edid/lg-tv.bin"
    # Force the connector to appear connected even when the TV is off
    "video=HDMI-A-3:D"
    "ipv6.disable" 
    "nvidia-drm.modeset=1"
    # (Optional) Lock a boot-time mode; comment if you don’t want this.
    # Common examples:
    "video=HDMI-A-3:3840x2160@120"
    # "video=HDMI-A-3:3840x2160@60"
  ];

  systemd.services.nvidia-persistenced.enable = true;

  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

  # ==== NETWORK ====
  networking = {
    hostName = "tower"; 
    hostId = "28133080";
    networkmanager.enable = false;
    useDHCP = false; 
    enableIPv6 = false;
    interfaces = {
      enp6s0.ipv4.addresses = [{
        address = "192.168.1.7";
        prefixLength = 24;
      }];
    };
    defaultGateway = {
      address = "192.168.1.1";
      interface = "enp6s0";
    };
    nameservers = [ "192.168.1.5" "1.1.1.1" ];
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 8080 57621 ];
      allowedUDPPorts = [ 5353 ];
    };
  };

  # ==== NIX FLAKES ====
  nix.settings.extra-platforms = [ "aarch64-linux" ];
  # trusted users
  nix.settings.trusted-users = [ "murphy" ];

  # ==== UDEV ====
    services.udev = {
        packages = [
          pkgs.yubikey-personalization
          pkgs.yubikey-manager
        ];
        extraRules = ''
          # iPhone
          SUBSYSTEM=="usb", ATTR{idVendor}=="05ac", MODE="0666", GROUP="plugdev"
          ${builtins.readFile ../../shared/udev/50-zsa.rules}
          ${builtins.readFile ../../shared/udev/50-stm.rules}
          ${builtins.readFile ../../shared/udev/69-probe-rs.rules}
          ${builtins.readFile ../../shared/udev/70-pro-controller.rules}
        '';
    };

  # ==== CUPS ====
  services.printing.enable = true;

  # ==== USERS ====
  users.users.murphy = {
    isNormalUser = true;
    description = "murphy";
    extraGroups = [ "networkmanager" "wheel" "docker" "plugdev" ];
    hashedPasswordFile = config.sops.secrets."passwords/tower/murphy".path;
  };

  # ==== BASH ====
  programs.bash = {
    interactiveShellInit = ''eval "$(direnv hook bash)"'';
    shellAliases = {
      vim = "nvim";
    };
  }; 

  # ==== VIRTUALIZATION ====
  virtualisation = {
    libvirtd.enable = true;
    spiceUSBRedirection.enable = true;
  };

  programs.virt-manager.enable = true;
  users.groups.libvirtd.members = [ "murphy" ];

  # ==== GROUPS ====
  users.groups.plugdev = {
    gid = 132;
  };

  services.pcscd = {
    enable = true;
    plugins = [ pkgs.ccid ];
  };

  programs.gnupg = {
    agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-tty;
    };
  };
  
  # ==== SYSTEM PACKAGES ====
  environment.systemPackages = with pkgs; [
    age
    direnv
    docker
    docker-compose
    freecad
    gcc
    git 
    grub2
    ifuse
    libimobiledevice
    nfs-utils
    pam_u2f
    pinentry-tty
    protonmail-desktop
    qemu
    sops
    usbmuxd
    xclip
    yubikey-agent
    yubikey-manager
    yubikey-personalization
    yubioath-flutter
  ];

  system.stateVersion = "25.11";
}
