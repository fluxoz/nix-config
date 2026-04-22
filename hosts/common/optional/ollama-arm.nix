{config, pkgs, ...}: 

let 
  ollama-latest = pkgs.stdenvNoCC.mkDerivation {
    pname = "ollama";
    version = "0.20.1";                                 # ← update if a newer one is out

    src = pkgs.fetchurl {
      url = "https://github.com/ollama/ollama/releases/download/v0.20.1/ollama-linux-arm64.tar.zst";
      # Get the correct hash with this one-time command:
      # nix-prefetch-url --type sha256 https://github.com/ollama/ollama/releases/download/v0.20.1/ollama-linux-amd64
      sha256 = "sha256-15lrg4ymscz7fpq8qchihw49nh3g5bfz88gnz8b2lbaxilc5a0ql";
    };
    
    nativeBuildInputs = [ pkgs.zstd ];
    dontUnpack = true;   # we unpack manually because it's .tar.zst
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      # Extract the ollama binary from the tar.zst (it sits at the root of the archive)
      tar --zstd -x -f $src -C $out/bin --strip-components=0 ollama
      chmod +x $out/bin/ollama
      runHook postInstall
    '';

    meta.mainProgram = "ollama";
  };
in
{
  # Then update your service
  services.ollama = {
    enable = true;
    package = ollama-latest;          # ← this line changed
    # package = pkgs.ollama-vulkan;  # (you can keep the old one for now if you want)
    openFirewall = true;
    host = "0.0.0.0";
    port = 11434;
    loadModels = [ "gemma4:e4b" ];
  };
}
