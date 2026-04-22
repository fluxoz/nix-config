{ ... }:

let
  diskIds = {
    data1 = "/dev/disk/by-id/ata-WDC_WD5000AACS-00G8B1_WD-WCAUH0982912";  # former sda
    data2 = "/dev/disk/by-id/ata-WDC_WD10EZEX-00BN5A0_WD-WCC3F0AVC1EC"; # former sdb
    data3 = "/dev/disk/by-id/ata-ST500LM021-1KJ152_W6211A1D";        # former sdc
    boot  = "/dev/disk/by-id/usb-Verbatim_STORE_N_GO_CCYYMMDDHHmmSS942G3L-0:0"; # former sdd
  };
in

{
  disko.devices = {
    disk = {
      data1 = {
        type = "disk";
        device = diskIds.data1;
        content = {
          type = "gpt";
          partitions = {
            linear = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "bigbucket";
              };
            };
          };
        };
      };
      data2 = {
        type = "disk";
        device = diskIds.data2;
        content = {
          type = "gpt";
          partitions = {
            linear = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "bigbucket";
              };
            };
          };
        };
      };
      data3 = {
        type = "disk";
        device = diskIds.data3;
        content = {
          type = "gpt";
          partitions = {
            linear = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "bigbucket";
              };
            };
          };
        };
      };

      bootdisk = {
        type = "disk";
        device = diskIds.boot;
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1G";                  # Larger than your current ~108M for safety
              type = "EF02";                # BIOS boot partition for old GRUB
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/boot";
              };
            };
          };
        };
      };
    };

    # The "big bucket" — linear concatenation (no redundancy)
    mdadm = {
      bigbucket = {
        type = "mdadm";
        level = "linear";                 # This is the key: linear, not raid1 or raid0
        metadata = "1.2";
        content = {
          type = "lvm_pv";
          vg = "vg";
        };
      };
    };

    # LVM layer on top of the big concatenated bucket
    lvm_vg = {
      vg = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "100%FREE";            
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [ "noatime" ];
            };
          };
          swap = {
            size = "16G";                 
            content = {
              type = "swap";
            };
          };
        };
      };
    };
  };
}
