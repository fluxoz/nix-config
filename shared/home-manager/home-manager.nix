{ config, pkgs, lib, nixvim, homeManagerModule,  ... }:
with lib;
let 
  cfg = config.home-manager;
in
{
  imports = [
    homeManagerModule
  ];

  options.home-manager = {
    desktopUser = mkOption {
      type = types.bool;
      default = false;
    };
  };
  config.home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.murphy = {...}: import ./murphy.nix {
      inherit config pkgs lib nixvim;
      desktopUser = cfg.desktopUser;
    };
  };
}
