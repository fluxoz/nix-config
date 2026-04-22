{pkgs, ...}:
{
    environment.systemPackages = with pkgs; [
      quickemu
      spice-gtk
    ];
    boot.kernelModules = [ "kvm-intel" ];
}
