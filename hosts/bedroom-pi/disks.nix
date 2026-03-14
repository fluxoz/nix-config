{ lib, ... }:

{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/mmcblk0";
    content = {
      type = "gpt";
      partitions = {
        FIRMWARE = {
          priority = 1;
          size = "256M";
          type = "0700";  
          attributes = [ 0 ];
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot/firmware";
            mountOptions = [
              "noatime"
              "noauto"
              "x-systemd.automount"
              "x-systemd.idle-timeout=1min"
            ];
          };
        };
        ESP = {
          label = "ESP";
          size = "1G";
          type = "EF00";  # Linux filesystem
          attributes = [
            2
          ];
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [
              "noatime"
              "noauto"
              "x-systemd.automount"
              "x-systemd.idle-timeout=1min"
              "umask=0077"
            ];
          };
        };
        root = {
          type = "8305";
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}

