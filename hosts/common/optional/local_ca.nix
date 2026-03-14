{ self, ...}:
{
  security.pki.certificateFiles = [ "${self}/shared/local_tls/rootCA.pem" ];
}
