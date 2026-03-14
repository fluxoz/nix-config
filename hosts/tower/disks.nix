{ lib, ... }: {
  disko.devices = {
    disk = {
      nvme0n1 = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            root = {
              size = "100%";
              content = {
                type = "mdadm";
                name = "raidroot";
              };
            };
          };
        };
      };
      nvme1n1 = {
        type = "disk";
        device = "/dev/nvme1n1";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1G";
              type = "EF00";  # EFI System Partition if UEFI; adjust if legacy BIOS
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "mdadm";
                name = "raidroot";
              };
            };
          };
        };
      };
    };
    mdadm = {
      raidroot = {
        type = "mdadm";
        level = 1;
        metadata = "1.0";  # For boot compatibility if needed
        content = {
          type = "luks";
          name = "cryptroot";
          # settings.keyFile = "/tmp/secret.key";  # Optional: for auto-unlock with keyfile
          extraOpenArgs = [ "--allow-discards" ];  # Optional: for SSD trim
          content = {
            type = "filesystem";
            format = "ext4";  # Or "btrfs"/"xfs" as preferred; your current mount suggests ext4 or similar
            mountpoint = "/";
          };
        };
      };
    };
  };
}
