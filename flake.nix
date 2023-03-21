{
  description = "Mars Research Homepage";

  inputs = {
    mars-std.url = "github:mars-research/mars-std";
  };

  outputs = { self, mars-std, ... }: let
    supportedSystems = mars-std.lib.defaultSystems;
  in mars-std.lib.eachSystem supportedSystems (system: let
    pkgs = mars-std.legacyPackages.${system};

    src = pkgs.nix-gitignore.gitignoreSource [] ./.;
    vendorSha256 = "sha256-uEzihbpSv5iHwwoNYA9s9o/fRk1MwA45cNxthYj2ASc=";

    website = pkgs.stdenv.mkDerivation {
      name = "mars-research-homepage";
      inherit src;

      GIT_SSL_CAINFO = "${pkgs.cacert}/etc/ssl/certs/ca-certificates.crt";

      NIX_SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt";
      nativeBuildInputs = with pkgs; [ go hugo openssl_1_1 ];

      buildPhase = ''
        ln -sf ${hugoVendor} _vendor
        hugo
      '';

      installPhase = ''
        cp -r public $out
      '';

      dontFixup = true;
    };

    hugoVendor = pkgs.stdenv.mkDerivation {
      name = "mars-research-homepage-vendor";

      inherit src;

      nativeBuildInputs = with pkgs; [ go hugo
      (git.override {openssl = openssl_1_1;}) ];

      GIT_SSL_CAINFO = "${pkgs.cacert}/etc/ssl/certs/ca-certificates.crt";

      NIX_SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt";

      buildPhase = ''
        rm -rf /build/hugo_cache
        hugo mod vendor
      '';

      installPhase = ''
        cp -r _vendor $out
      '';

      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = vendorSha256;
    };
  in {
    devShell = pkgs.mkShell {
      inputsFrom = [ website ];
    };
    packages.website = website;
    defaultPackage = website;
  });
}
