{pkgs, ...}:

{
  nix.extraOptions = "experimental-features = nix-command flakes";
  services.openssh.enable = true;
  services.openssh.settings = {
    PermitRootLogin = "yes";
  };
  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../shared/authorized_keys
  ];
}
