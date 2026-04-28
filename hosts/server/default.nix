{ self, config, lib, nixvim, pkgs, ... }:

let
  nvim = nixvim.packages.x86_64-linux.default;
in
{
  imports = [
    ../../shared/home-manager/home-manager.nix
    ./disks.nix   
  ];

  sops = {
    secrets = {
      "passwords/server/murphy" = {
        neededForUsers = true;
      };
      "passwords/server/root" = {
        neededForUsers = true;
      };
    };
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

  users.users = { 
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
