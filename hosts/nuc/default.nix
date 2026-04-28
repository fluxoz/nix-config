{ self, config, pkgs, nixvim, backup-key, photos-key, jellyfin-key, lan-key, ... }:
let
  # Reference the nvim package from the nixvim flake
  nvim = nixvim.packages.x86_64-linux.default;
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
  ];
  
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      # AMD Vega driver
      mesa
      libva
      libva-utils
      # Intel Qsv driver
      intel-media-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  environment.variables = {
    # LIBVA_DRIVER_NAME = "radeonsi";
    LIBVA_DRIVER_NAME = "iHD";
  };

  sops = {
    secrets = {
      "passwords/nuc/murphy" = {
        neededForUsers = true;
      };
      "passwords/nuc/root" = {
        neededForUsers = true;
      };
      "zfs/backup-key" = {
        sopsFile = backup-key;
        format = "binary";
        owner = "root";
        group = "root";
        mode = "0400";
      };
      "zfs/jellyfin-key" = {
        sopsFile = jellyfin-key;
        format = "binary";
        owner = "root";
        group = "root";
        mode = "0400";
      };
      "zfs/photos-key" = {
        sopsFile = photos-key;
        format = "binary";
        owner = "root";
        group = "root";
        mode = "0400";
      };
      "lan-key" = {
        sopsFile = lan-key;
        format = "binary";
        owner = "nginx";
        group = "nginx";
        mode = "0600";
      };
    };
  };
  
  # ==== BOOT SETTINGS ====
  boot = {
    loader =  {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelParams = [ 
      "usbcore.autosuspend=-1"
      "usb_storage"
    ];
    extraModprobeConfig = ''
      options usb-storage delay_use=1
    '';
    initrd.kernelModules = [ "amdgpu" ];
  };

  # ==== ZFS ====
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs = {
    forceImportRoot = false;
    extraPools = [ "storage" ];
    requestEncryptionCredentials = [ 
      "storage/backup"
      "storage/jellyfin"
      "storage/photos" 
    ];
  };
  services.zfs = {
    autoScrub.enable = true;
    autoScrub.interval = "quarterly";
  };

  # ==== Cron ====
  services.cron = 
  let 
    disk-keep-alive = ./. + "/disk-keep-alive.sh"; 
    in {
      enable = true;
      systemCronJobs = [ 
        "@reboot root ${disk-keep-alive}"
      ];
    };

  # ==== Swapfile ====
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 16*1024;
  }];

  # ==== Virtualization ====
  virtualisation.libvirtd.enable = true;

  users = { 
    groups = {
      storage = {
        gid = 500;
      };
    };
    users = { 
      root = {
        hashedPasswordFile = config.sops.secrets."passwords/nuc/root".path;
        openssh.authorizedKeys.keyFiles = [ 
          ../../shared/authorized_keys
        ];
      };
      murphy = {
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets."passwords/nuc/murphy".path;
        extraGroups = [ "wheel" "docker" "storage" ]; # Add user to sudo group
        openssh.authorizedKeys.keyFiles = [ 
          ../../shared/authorized_keys
        ];
      };
      jellyfin = {
        isSystemUser = true;
        uid = 997;
      };
    };
  };
  nix.settings.trusted-users = [ "@wheel" ];

  # ===== NETWORKING =====
  networking = {
    defaultGateway = "192.168.1.1";
    nameservers = [
      "192.168.1.5"
      "1.1.1.1"
    ];
    hostName = "nuc";
    hostId = "28133081";
    enableIPv6 = true;
    useDHCP = false;
    networkmanager.enable = false;
    interfaces.enp0s31f6 = {
      ipv4.addresses = [{
        address = "192.168.1.8";
        prefixLength = 24;
      }];
    };
    firewall = {
      enable = true; 
      allowedTCPPorts = [ 
        111   # nfs
        20048 # nfs
        2049  # nfs
        22    # ssh
        32765 # nfs
        32768 # nfs
        8080
        8443
        443
        # 5900  # vnc/vm 
        # 6080  # vnc/vm
        80    # http
        # 9420 
      ];
    };
  };

  # ==== OTHER SERVICES =====
  services.udev.extraRules = ''
    # Disable USB suspend on all storage devices
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="on"
  '';

  # ==== NFS ====
  services.nfs.server = {
    enable = true;
    mountdPort = 20048;
    statdPort = 32765;
    lockdPort = 32768;
    exports = ''
      /storage/jellyfin 192.168.1.0/24(rw,sync,no_subtree_check,root_squash,insecure,anonuid=997,anongid=500)
      /storage/photos 192.168.1.0/24(rw,sync,no_subtree_check,root_squash,insecure)
      /storage/backup 192.168.1.0/24(rw,sync,no_subtree_check,root_squash,insecure,anonuid=1001,anongid=500)
    '';
  };

  services.starfin = {
    enable = true;
    videoLibraryPath = "/storage/backup/media";
    cacheDir = "/storage/backup/starfin_cache";
    cacheStrategy = "aggressive";
    # design = "neubrutalist";
    # devMetrics = true;
    bindAddr = "127.0.0.1";
    port = 8089;
    user = "murphy";
    group = "storage";
    passwordProtection = true;
  };
  
  services.immich = {
    enable = true;
    port = 2283;
    host = "0.0.0.0";
    group = "storage";
    mediaLocation = "/storage/photos";
    # environment = {
    #   UPLOAD_LOCATION = "/storage/photos";
    # };
  };

  services.unifi = {
    enable = true;
    openFirewall = true;
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts = {
      "unifi.nuc.lan" = {
        forceSSL = true;
        sslCertificate = "${self}/shared/local_tls/lan.pem";
        sslCertificateKey = config.sops.secrets."lan-key".path;
        locations."/" = {
          proxyPass = "https://127.0.0.1:8443";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
      };
      "vm.nuc.lan" = {
        forceSSL = true;
        sslCertificate = "${self}/shared/local_tls/lan.pem";
        sslCertificateKey = config.sops.secrets."lan-key".path;
        locations = {
          "= /" = {
            extraConfig = ''
              return 302 /vnc.html;
            '';
          };
          "/" = {
            extraConfig = ''
              proxy_pass http://127.0.0.1:6080;
              proxy_http_version 1.1;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
            '';
          };
        };
      };
      "immich.nuc.lan" = {
        forceSSL = true;
        sslCertificate = "${self}/shared/local_tls/lan.pem";
        sslCertificateKey = config.sops.secrets."lan-key".path;
        locations."/" = {
          proxyPass = "http://127.0.0.1:2283";
          proxyWebsockets = true;
          recommendedProxySettings = true;
          extraConfig = ''
            client_max_body_size 50000M;
            proxy_read_timeout 600s;
            proxy_send_timeout 600s;
            send_timeout 600s;
          '';
        };
      };
      "jellyfin.nuc.lan" = {
        forceSSL = true;
        sslCertificate = "${self}/shared/local_tls/lan.pem";
        sslCertificateKey = config.sops.secrets."lan-key".path;
        locations."/" = {
          extraConfig = ''
            proxy_pass http://127.0.0.1:8096;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # Fix for WebSocket support
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            # Rewrite base path
            proxy_redirect off;
            sub_filter_once off;
            sub_filter 'href="/' 'href="/jellyfin/';
            sub_filter 'src="/' 'src="/jellyfin/';
          '';
        };
      };
      "starfin.nuc.lan" = {
        forceSSL = true;
        sslCertificate = "${self}/shared/local_tls/lan.pem";
        sslCertificateKey = config.sops.secrets."lan-key".path;
        locations."/" = {
          extraConfig = ''
            proxy_pass http://127.0.0.1:8089;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # Fix for WebSocket support
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          '';
        };
      };
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
    };
  };

  services.avahi = {
    enable = true; # Enable Avahi for network discovery
    nssmdns4 = true;
  };

  # System Updates
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false; # Change to true if you want auto-reboot after updates

  # Power Management
  powerManagement.cpuFreqGovernor = "powersave"; # Energy-efficient CPU governor

  # Software
  environment.systemPackages = with pkgs; [
    git
    htop
    jellyfin
    jellyfin-ffmpeg
    jellyfin-web
    inotify-tools
    tmux
    vim
    nvim
    qemu
    clinfo
  ];

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    dataDir = "/storage/jellyfin/data";
    configDir = "/storage/jellyfin/config";
    cacheDir = "/storage/jellyfin/cache";
  };

  # programs.home-manager.enable = true;
  systemd = {
    services = {
      enforce-jellyfin-downloads = {
        description = "Fix Jellyfin Downloads Permissions";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          ExecStart = pkgs.writeShellScript "fix-downloads.sh" ''
            WATCH_DIR="/storage/jellyfin/downloads/incomplete"
            OWNER="jellyfin"
            GROUP="storage"
            PERMS="0775"

            # Initial fix
            chown -R "$OWNER:$GROUP" "$WATCH_DIR"
            find "$WATCH_DIR" -type d -exec chmod "$PERMS" {} +
            find "$WATCH_DIR" -type f -exec chmod "$PERMS" {} +

            # Watch and fix
            ${pkgs.inotify-tools}/bin/inotifywait -mrq -e create -e moved_to -e attrib --format "%w%f" "$WATCH_DIR" | while read path; do
              chown "$OWNER:$GROUP" "$path"
              chmod "$PERMS" "$path"
            done
          '';
          User = "root";
        };
      };
      vm = {
        description = "Start NixOS VM in homedir";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          User = "murphy";
          WorkingDirectory = "/home/murphy/vm";
          ExecStart = "/home/murphy/vm/result/bin/run-nixos-vm-vm";
          Restart = "always";
        };
      };
      journal-gatewayd.enable = true;
    };
  };
  # Logging
  system.stateVersion = "25.05"; 
}
