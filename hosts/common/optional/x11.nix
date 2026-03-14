{...}:
{
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    xkb.variant = "";
    displayManager = {
      sessionCommands = ''
        xset -dpms 
        xset s off
        xset s noblank
      '';
    };
  };
}
