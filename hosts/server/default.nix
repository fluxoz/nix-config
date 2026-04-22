{ config, lib, nixvim, pkgs, ... }:

let
  inherit (config.disko.devices.disk) bootdisk;  # optional, for referencing devices
  nvim = nixvim.packages.x86_64-linux.default;
in
{
  imports = [
    ../../shared/home-manager/home-manager.nix
    ./disks.nix   
  ];

  # === Boot configuration for linear mdadm + LVM on old BIOS server ===
  boot.loader.grub = {
    enable = true;
    device = "nodev";                    # BIOS mode (not EFI)
    devices = [                          # Install GRUB to EVERY physical disk for best chance of booting
      bootdisk.device
    ];
  };

  # Critical: make sure the linear mdadm array and LVM activate very early in initrd
  boot.swraid.enable = true;
  boot.initrd.availableKernelModules = [ "md_linear" "dm_raid" "dm_snapshot" "dm_mod" ];
  boot.initrd.kernelModules = [ "dm-raid" ];

  # === Basic system settings (expand as needed) ===
  networking.hostName = "server";   # change this

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";  # or "yes" if you prefer
  };

  users = { 
    root = {
      hashedPasswordFile = config.sops.secrets."passwords/server/root".path;
      openssh.authorizedKeys.keyFiles = [ 
        ../../shared/authorized_keys
      ];
    };
    murphy = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets."passwords/server/murphy".path;
      extraGroups = [ "wheel" ]; # Add user to sudo group
      openssh.authorizedKeys.keyFiles = [ 
        ../../shared/authorized_keys
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    vim git htop
    nvim
  ];

  system.stateVersion = "25.11"; 
}
