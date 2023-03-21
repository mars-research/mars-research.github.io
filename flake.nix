{
  description = "Mars Research Homepage";

  inputs = {
    mars-std.url = "github:mars-research/mars-std";
    papermod = {
      url = "github:adityatelange/hugo-PaperMod";
      flake = false;
    };
  };

  outputs = { self, mars-std, papermod, ... }: let
    supportedSystems = mars-std.lib.defaultSystems;
  in mars-std.lib.eachSystem supportedSystems (system: let
    pkgs = mars-std.legacyPackages.${system};

    src = pkgs.nix-gitignore.gitignoreSource [] ./.;

    website = pkgs.stdenv.mkDerivation {
      name = "mars-research-homepage";
      inherit src;

      nativeBuildInputs = with pkgs; [ hugo ];

      HUGO_MODULE_IMPORTS_PATH = papermod;

      buildPhase = ''
        hugo
      '';

      installPhase = ''
        cp -r public $out
      '';

      dontFixup = true;
    };
  in {
    devShell = pkgs.mkShell {
      inputsFrom = [ website ];
      HUGO_MODULE_IMPORTS_PATH = papermod;
    };
    packages.website = website;
    defaultPackage = website;
  });
}
