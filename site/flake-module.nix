{ ... }: {
  perSystem = system: { config, self', inputs', pkgs, lib, ... }: {
    packages.websitePackage = pkgs.stdenvNoCC.mkDerivation {
      name = "site";
      nativeBuildInputs = [ pkgs.pandoc ];
      src = lib.cleanSourceWith {
        filter = path: type:
          path == ./.
          || baseNameOf path == "index.html";
        src = ./.;
      };
      buildPhase = ''
        pandoc --from docbook --to html5 \
          ${config.packages.optionsDocBook} >options.html
      '';
      installPhase = ''
        mkdir -p $out
        cp *.html $out/
      '';
    };
  };
}
