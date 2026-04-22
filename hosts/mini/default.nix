{ self, config, lib, pkgs, nixvim, ... }:
let
  # Reference the nvim package from the nixvim flake
  nvim = nixvim.packages.x86_64-linux.default;
  ollama-0_20_1 = pkgs.ollama-vulkan.overrideAttrs (old: {
    version = "0.20.1";
    src = pkgs.fetchFromGitHub {
      owner = "ollama";
      repo = "ollama";
      tag = "v0.20.1";
      hash = "sha256-CfDoP1UJF8vl3CkLg8diwQjtEwDClR4DXc2hXLdm1bo=";
      fetchSubmodules = true;
    };
    proxyVendor = true;
    vendorHash = "sha256-Lc1Ktdqtv2VhJQssk8K1UOimeEjVNvDWePE9WkamCos=";
    doCheck = false;
  });
in

{
  # Import the hardware configuration dynamically
  imports = [
    ../common/core/nixos.nix
    ../common/core/unfree.nix
    ../common/core/timezone.nix
    ../common/optional/local_ca.nix
    ../../shared/home-manager/home-manager.nix
    ./hardware-configuration.nix
    # ../common/optional/ollama-arm.nix
  ];
  
  sops = {
    secrets = {
      "passwords/mini/murphy" = {
        neededForUsers = true;
      };
      "passwords/mini/root" = {
        neededForUsers = true;
      };
    };
  };

  hardware.asahi.peripheralFirmwareDirectory = ./firmware;
  hardware.asahi.enable = true;
  
  users = { 
    groups = {
      storage = {
        gid = 500;
      };
    };
    users = { 
      root = {
        hashedPasswordFile = config.sops.secrets."passwords/mini/root".path;
        openssh.authorizedKeys.keyFiles = [ 
          ../../shared/authorized_keys
        ];
      };
      murphy = {
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets."passwords/mini/murphy".path;
        extraGroups = [ "wheel" "docker" "storage" ]; # Add user to sudo group
        openssh.authorizedKeys.keyFiles = [ 
          ../../shared/authorized_keys
        ];
      };
    };
  };

  nix.settings.trusted-users = [ "@wheel" ];

  # ===== NETWORKING =====
  networking = {
    defaultGateway = "192.168.2.1";
    nameservers = [
      "8.8.8.8"
      "1.1.1.1"
    ];
    hostName = "mini";
    useDHCP = false;
    enableIPv6 = false;
    networkmanager.enable = false;
    interfaces.end0 = {
      ipv4.addresses = [{
        address = "192.168.2.2";
        prefixLength = 24;
      }];
    };
    firewall = {
      enable = true; 
      allowedTCPPorts = [ 
        22    # ssh
        8080    # http
      ];
    };
  };

  # services.zeroclaw = {
  #   enable = true;
  #   provider = "ollama";
  # };

  services.ollama = {
    enable = true;
    package = ollama-0_20_1;
    openFirewall = true;
    host = "0.0.0.0";
    port = 11434;
    loadModels = [ "gemma4:e4b"];
  };

  # services.tailscale = {
  #   enable = true;
  # };
  
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
    };
  };

  # System Updates
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false; # Change to true if you want auto-reboot after updates

  # Software
  environment.systemPackages = with pkgs; [
    git
    htop
    tmux
    vim
    nvim
    qemu
    clinfo
  ];
  system.stateVersion = "25.11"; 
}
