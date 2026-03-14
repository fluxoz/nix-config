{ config, ... }:
{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = {
    enable32Bit = true;
    enable = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  }; 
}
