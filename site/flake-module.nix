{ ... }: {
  perSystem = { config, self', inputs', pkgs, lib, ... }:
    let
      inherit (lib) filter any hasPrefix concatMap removePrefix;

      libNix = import ../lib.nix { inherit lib; };
      eval = libNix.evalFlakeModule { self = { }; } { };
      opts = eval.options;

      filterTransformOptions = { sourceName, sourcePath, baseUrl }:
        let sourcePathStr = toString sourcePath;
        in
        opt:
        let declarations = concatMap
          (decl:
            if hasPrefix sourcePathStr (toString decl)
            then
              let subpath = removePrefix sourcePathStr (toString decl);
              in [{ url = baseUrl + subpath; name = sourceName + subpath; }]
            else [ ]
          )
          opt.declarations;
        in
        if declarations == [ ]
        then opt // { visible = false; }
        else opt // { inherit declarations; };

      optionsDoc = { sourceName, baseUrl, sourcePath, title }: pkgs.runCommand "${sourceName}-doc"
        {
          nativeBuildInputs = [ pkgs.libxslt.bin ];
          inputDoc = (pkgs.nixosOptionsDoc {
            options = opts;
            documentType = "none";
            transformOptions = filterTransformOptions {
              inherit sourceName baseUrl sourcePath;
            };
          }).optionsDocBook;
          inherit title;
        } ''
        xsltproc --stringparam title "$title" \
          -o $out ${./options.xsl} \
          "$inputDoc"
      '';
    in
    {

      packages = {

        siteContent = pkgs.stdenvNoCC.mkDerivation {
          name = "site";
          nativeBuildInputs = [ pkgs.pandoc pkgs.libxslt.bin ];
          src = lib.cleanSourceWith {
            filter = path: type:
              path == ./.
              || baseNameOf path == "index.html";
            src = ./.;
          };
          coreOptions = optionsDoc {
            title = "Core Options";
            sourceName = "flake-parts";
            baseUrl = "https://github.com/hercules-ci/flake-parts/blob/main";
            sourcePath = ../.;
          };
          # pandoc
          htmlBefore = ''
            <html>
            <head>
            <title>Options</title>
            <style type="text/css">
              a:target { background-color: rgba(239,255,0,0.5); }
              body {
                max-width: 40em;
                margin-left: auto;
                margin-right: auto;
              }
            </style>
            </head>
            <body>
          '';
          htmlAfter = ''
            </body>
            </html>
          '';
          buildPhase = ''
            (echo "$htmlBefore"; pandoc --verbose --from docbook --to html5 $coreOptions; echo "$htmlAfter"; ) >options.html
          '';
          installPhase = ''
            mkdir -p $out
            cp *.html $out/
          '';
        };
      };
    };
}
