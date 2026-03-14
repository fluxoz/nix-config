{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Boot settings
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  networking = {
    hostName = "bedroom-pi";
    networkmanager.enable = false;
    wireless = {
      enable = false;
      networks."Last Resort".psk = "clearthewater"; 
      extraConfig = "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=wheel";
    };
  };

  # Timezone and locale
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  # Define user
  users.users.nixos = {
    isNormalUser = true;
    hashedPassword = "$y$j9T$6CuPT8urA1ry0PeGhsySW.$011z/yx5ojBC1ZcHC85DWV0/5DfYuLxR4plLohuybK7";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.bash;
  };

  services = {
    getty.autologinUser = "nixos";
    xserver = {
      enable = true;
      windowManager.openbox.enable = true;
      displayManager = {
        startx = {
          enable = true;
          extraCommands = ''
                ${pkgs.openbox}/bin/openbox &
                ${pkgs.chromium}/bin/chromium \
                --kiosk \
                --noerrdialogs \
                --disable-infobars \
                --disable-session-crashed-bubble \
                --start-fullscreen \
                http://192.168.1.8:8096
          '';
        };
      };
    };
  };

  # Needed packages
  environment.systemPackages = with pkgs; [
    chromium
    openbox
    xorg.xinit
    networkmanager
    xdg-utils
  ];

  system.stateVersion = "25.05";
}

