{ config, pkgs, lib, nixvim, desktopUser ? false, niriUser ? false, ... }:
{
  imports = [
    ./packages.nix
  ];

  _module.args.nixvim = nixvim;

  home.username = "murphy";
  xresources.properties = if desktopUser then {
    "Xcursor.size" = 12;
    "Xft.dpi" = 110;
  } else null;

  my-packages = {
    isDesktopUser = desktopUser;
  }; 

  fonts.fontconfig.defaultFonts = {
    serif = [ "Iosevka Nerd Font Mono" ];
    sansSerif = [ "Iosevka Nerd Font Mono" ];
    monospace = [ "Iosevka Nerd Font Mono" ];
  };

  programs.ghostty = if desktopUser then
  lib.mkForce {
    enable = true;
    settings = {
      font-family = "Iosevka Nerd Font Mono";
      font-size = 12;
      term = "xterm-256color";
    };
  } else {};

  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"'';
    shellAliases = {
      vim = "nvim";
      lah = "ls -lath";
      la = "ls -a";
      l = "ls";
      wg = "watch -n10 gh agent-task list -L";
      gc = "gh issue create --assignee @copilot";
    };
  };

  programs.git = if desktopUser
  then {
    enable = true;
    settings = {
      user = {
        name = "fluxoz";
        email = "john@coyote.technology";
      };
      credential.helper = "${
        pkgs.git.override { withLibsecret = true; }
      }/bin/git-credential-libsecret";
    };
  } else {};

  home.stateVersion = "25.11";
  # Let home Manager install and manage itself
  programs.home-manager.enable = true;
} 
