{ inputs, ... }: {
  perSystem = { config, self', inputs', pkgs, lib, ... }:
    let
      inherit (lib) filter any hasPrefix concatMap removePrefix;

      libNix = import ../lib.nix { inherit lib; };
      eval = libNix.evalFlakeModule { self = { inputs = { inherit (inputs) nixpkgs; }; }; } {
        imports = [
          inputs.pre-commit-hooks-nix.flakeModule
          inputs.hercules-ci-effects.flakeModule
          inputs.haskell-flake.flakeModule
          inputs.dream2nix.flakeModuleBeta
        ];
      };
      opts = eval.options;

      filterTransformOptions = { sourceName, sourcePath, baseUrl }:
        let sourcePathStr = toString sourcePath;
        in
        opt:
        let
          declarations = concatMap
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

      optionsDoc = { sourceName, baseUrl, sourcePath, title }: pkgs.runCommand "option-doc-${sourceName}"
        {
          nativeBuildInputs = [ pkgs.libxslt.bin pkgs.pandoc ];
          inputDoc = (pkgs.nixosOptionsDoc {
            options = opts;
            documentType = "none";
            transformOptions = filterTransformOptions {
              inherit sourceName baseUrl sourcePath;
            };
            warningsAreErrors = true; # not sure if feasible long term
            markdownByDefault = true;
          }).optionsDocBook;
          inherit title;
        } ''
        xsltproc --stringparam title "$title" \
          -o options.db.xml ${./options.xsl} \
          "$inputDoc"
        mkdir $out
        pandoc --verbose --from docbook --to html options.db.xml >$out/options.md;
      '';

      repos = {
        flake-parts = {
          title = "Core Options";
          sourceName = "flake-parts";
          baseUrl = "https://github.com/hercules-ci/flake-parts/blob/main";
          sourcePath = ../.;
        };
        pre-commit-hooks-nix = {
          title = "pre-commit-hooks.nix";
          sourceName = "pre-commit-hooks.nix";
          baseUrl = "https://github.com/hercules-ci/pre-commit-hooks.nix/blob/flakeModule";
          sourcePath = inputs.pre-commit-hooks-nix;
        };
        hercules-ci-effects = {
          title = "hercules-ci-effects";
          sourceName = "hercules-ci-effects";
          baseUrl = "https://github.com/hercules-ci/hercules-ci-effects/blob/master";
          sourcePath = inputs.hercules-ci-effects;
        };
        haskell-flake = {
          title = "haskell-flake";
          sourceName = "haskell-flake";
          baseUrl = "https://github.com/srid/haskell-flake/blob/master";
          sourcePath = inputs.haskell-flake;
        };
        dream2nix = {
          title = "dream2nix beta";
          sourceName = "dream2nix";
          baseUrl = "https://github.com/nix-community/dream2nix/blob/master";
          sourcePath = inputs.dream2nix;
        };
      };

      generatedDocs = lib.mapAttrs (k: optionsDoc) repos;
      generatedDocs' = lib.mapAttrs' (name: value: { name = "generated-docs-${name}"; inherit value; }) generatedDocs;

    in
    {
      packages = {
        siteContent = pkgs.stdenvNoCC.mkDerivation {
          name = "site";
          nativeBuildInputs = [ pkgs.mdbook ];
          src = ./.;
          buildPhase = ''
            runHook preBuild

            {
              while read ln; do
                case "$ln" in
                  *end_of_intro*)
                    break
                    ;;
                  *)
                    echo "$ln"
                    ;;
                esac
              done
              cat src/intro-continued.md
            } <${../README.md} >src/README.md
            
            mkdir -p src/options
            ${lib.concatStringsSep "\n"
              (lib.mapAttrsToList
                (name: generated: ''
                  cp '${generated}/options.md' 'src/options/${name}.md'
                '')
                generatedDocs)
            }

            mdbook build --dest-dir $out

            echo '<html><head><script>window.location.pathname = window.location.pathname.replace(/options.html$/, "") + "/options/flake-parts.html"</script></head><body><a href="options/flake-parts.html">to the options</a></body></html>' \
              >$out/options.html

            runHook postBuild
          '';
          dontInstall = true;
        };
      } // generatedDocs';
    };
}
