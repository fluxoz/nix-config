{pkgs, ...}:
{
  fonts = {
    fontconfig = {
      hinting = {
        style = "full";
        enable = true;
      };
      antialias = true;
    };
    packages = with pkgs; [
      cantarell-fonts
      nerd-fonts.iosevka
      nerd-fonts.fira-code
      nerd-fonts.symbols-only
      nerd-fonts.droid-sans-mono
    ];
  };
}

