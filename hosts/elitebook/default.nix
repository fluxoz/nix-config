{ config, pkgs, lib, nixvim, ... }:
let
  # Reference the nvim package from the nixvim flake
  nvim = nixvim.packages.x86_64-linux.default;
in

{
  # Import the hardware configuration dynamically
  imports = [
    ../../shared/home-manager/home-manager.nix
    ./hardware-configuration.nix
  ];
  
  # Basic system settings
  time.timeZone = "America/Los_Angeles"; # Adjust to your timezone

  #nix settings
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # ==== UNFREE PACKAGES ====
  nixpkgs.config.allowUnfree = true;

  # ==== BOOT SETTINGS ====
  boot = {
    loader =  {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelParams = [ 
      "ipv6.disable=1" 
      "usbcore.autosuspend=-1"
      "usb_storage"
    ];
    extraModprobeConfig = ''
      options usb-storage delay_use=1
    '';
  };

  # ==== AUDIO ====
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ==== KDE ====
  services.displayManager = {
    sddm.enable = true;
  };
  services.xserver.desktopManager.plasma6.enable = true;

  # ==== Swapfile ====
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 16*1024;
  }];

  # ==== FONTS ====;
  fonts = {
    fontconfig = {
      hinting = {
        style = "full";
        enable = true;
      };
      antialias = true;
    };
    packages = with pkgs; [
      cantarell-fonts
      nerd-fonts.iosevka
      nerd-fonts.fira-code
      nerd-fonts.symbols-only
      nerd-fonts.droid-sans-mono
    ];
  };



  # ==== Users and Groups ====
  users = { 
    groups = {
      storage = {
        gid = 500;
      };
    };
    users = { 
      john = {
        isNormalUser = true;
        hashedPassword = ''$6$IWzN/g2rPyMKpb/b$k9sXeq.YutOps0DxISkXSiUCZHhdffoNxsN4hHFlMqzxZ84RUiXrmNh22dHsiaZiEcuoGtH7ekQyrgV/a3I.I0'';
        extraGroups = [ "wheel" "docker" "storage" ]; # Add user to sudo group
        openssh.authorizedKeys.keyFiles = [ 
          ../../shared/authorized_keys
        ];
      };
    };
  };
  nix.settings.trusted-users = [ "@wheel" ];

  # ==== BASH ====
    programs.bash = {
      interactiveShellInit = ''eval "$(direnv hook bash)"'';
      shellAliases = {
        vim = "nvim";
      };
    }; 

  # ===== NETWORKING =====
  networking = {
    networkmanager = {
      enable = true;
    };
    hostName = "elitebook";
    enableIPv6 = false;
    useDHCP = false;
    firewall = {
      enable = true; 
      allowedTCPPorts = [ 
        22    # ssh
      ];
    };
  };
  # ==== CUPS ====
  services.printing.enable = true;

  hardware.bluetooth = {
    enable = true; # enables support for Bluetooth
    powerOnBoot = true; # powers up the default Bluetooth controller on boot
    settings = {
      General = {
        Privacy = "device";
        JustWorksRepairing = "always";
        Class = "0x000100";
        FastConnectable = "true";
      };
    };
  };

  services.tailscale = {
    enable = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
    };
  };

  # System Updates
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false; # Change to true if you want auto-reboot after updates

  # Power Management
  powerManagement.cpuFreqGovernor = "powersave"; # Energy-efficient CPU governor

  # Software
  environment.systemPackages = with pkgs; [
    git
    htop
    inotify-tools
    tmux
    vim
    nvim
    clinfo
  ];

  system.stateVersion = "25.11"; 
}
