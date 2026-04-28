{ config, lib, pkgs, nixvim, ... }:
let
  nvim = nixvim.packages.${pkgs.system}.default;
in
  {
    options.my-packages = {
      isDesktopUser = lib.mkEnableOption "Is this a desktop user?";
    };

    config = {
        home.packages = with pkgs; [
          aria2 # A lightweight multi-protocol & multi-source command-line download utility
          btop  # replacement of htop/nmon
          cowsay
          coreutils 
          direnv
          distrobox
          dnsutils  # `dig` + `nslookup`
          emacs
          ethtool
          eza # A modern replacement for ‘ls’
          file
          fzf # A command-line fuzzy finder
          gawk
          gdb
          gh
          glow # markdown previewer in terminal
          gnupg
          gnused
          gnutar
          gopls
          gzip
          htop
          iftop # network monitoring
          ifuse
          inetutils
          iotop # io monitoring
          ipcalc  # it is a calculator for the IPv4/v6 addresses
          iperf3
          jq # A lightweight and flexible command-line JSON processor
          ldns # replacement of `dig`, it provide the command `drill`
          lm_sensors # for `sensors` command
          lsof # list open files
          ltrace # library call monitoring
          mtr # A network diagnostic tool
          neofetch
          net-tools
          nh # nix cli helper
          nix-direnv
          nix-direnv
          nix-output-monitor
          nixos-anywhere
          nload
          nmap # A utility for network discovery and security auditing
          nnn # terminal file manager
          nvim  # Reference the nvim package from nixvim flake
          p7zip
          pciutils # lspci
          progress
          ripgrep # recursively searches directories for a regex pattern
          rust-analyzer
          simple-http-server
          ssh-to-age
          socat # replacement of openbsd-netcat
          strace # system call monitoring
          sysstat
          tcptraceroute
          tmux
          tree
          unzip
          usbutils # lsusb
          which
          xxd
          xz
          zip
          zls
          zstd
        ] ++ lib.optionals config.my-packages.isDesktopUser [
          auctex
          caligula # utility for disk imaging
          chromium
          discord
          ffmpeg-full
          firefox
          freecad
          gimp
          gnuradio
          gparted # disk utility
          hugo # static site generator
          jan # a tool for running local LLMs
          jq # A lightweight and flexible command-line JSON processor
          ghostty
          lutris
          orca-slicer
          ryubing
          signal-desktop
          steam
          texliveFull
          tradingview
          vlc
          vscode
          wine 
          winetricks
          zed-editor
        ];
    };
}
