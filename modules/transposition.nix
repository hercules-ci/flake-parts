{ config, lib, flake-parts-lib, ... }:

let
  inherit (lib)
    filterAttrs
    mapAttrs
    mkOption
    types
    ;
  inherit (lib.strings)
    escapeNixIdentifier
    ;

  transpositionModule = {
    options = {
      adHoc = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to provide a stub option declaration for {option}`perSystem.<name>`.

          The stub option declaration does not support merging and lacks
          documentation, so you are recommended to declare the {option}`perSystem.<name>`
          option yourself and avoid {option}`adHoc`.
        '';
      };
    };
  };

  perInputAttributeError = { flake, attrName, system, attrConfig }:
    # This uses flake.outPath for lack of a better identifier.
    # Consider adding a perInput variation that has a normally-redundant argument for the input name.
    # Tested manually with
    # perSystem = { inputs', ... }: {
    #   packages.extra = inputs'.nixpkgs.extra;
    #   packages.default = inputs'.nixpkgs.packages.default;
    #   packages.veryWrong = (top.config.perInput "x86_64-linux" inputs'.nixpkgs.legacyPackages.hello).packages.default;
    # };
    # transposition.extra = {};
    let
      attrPath = "${escapeNixIdentifier attrName}.${escapeNixIdentifier system}";
      flakeIdentifier =
        if flake._type or null != "flake"
        then
          throw "An attempt was made to access attribute ${attrPath} on a value that's supposed to be a flake, but may not be a proper flake."
        else
          builtins.addErrorContext "while trying to find out how to describe what is supposedly a flake, whose attribute ${attrPath} was accessed but does not exist" (
            toString flake.outPath
          );
      # This ought to be generalized by extending attrConfig, but this is the only known and common mistake for now.
      alternateAttrNameHint =
        if attrName == "packages" && flake?legacyPackages
        then # Unfortunately we can't just switch them out, because that will put packages *sets* where single packages are expected in user code, resulting in potentially much worse and more confusing errors down the line.
          "\nIt does define legacyPackages; try that instead?"
        else "";
    in
    if flake?${attrName}
    then
      throw ''
        Attempt to access ${attrPath} of flake ${flakeIdentifier}, but it does not have it.
        It does have attribute ${escapeNixIdentifier attrName}, so it appears that it does not support system type ${escapeNixIdentifier system}.
      ''
    else
      throw ''
        Attempt to access ${attrPath} of flake ${flakeIdentifier}, but it does not have attribute ${escapeNixIdentifier attrName}.${alternateAttrNameHint}
      '';


in
{
  options = {
    transposition = lib.mkOption {
      description = ''
        A helper that defines transposed attributes in the flake outputs.

        When you define `transposition.foo = { };`, definitions are added to the effect of (pseudo-code):

        ```nix
        flake.foo.''${system} = (perSystem system).foo;
        perInput = system: inputFlake: inputFlake.foo.''${system};
        ```

        Transposition is the operation that swaps the indices of a data structure.
        Here it refers specifically to the transposition between

        ```plain
        perSystem: .''${system}.''${attribute}
        outputs:   .''${attribute}.''${system}
        ```

        It also defines the reverse operation in [{option}`perInput`](#opt-perInput).
      '';
      type =
        types.lazyAttrsOf
          (types.submoduleWith { modules = [ transpositionModule ]; });
    };
  };

  config = {
    flake =
      lib.mapAttrs
        (attrName: attrConfig:
          mapAttrs
            (system: v: v.${attrName} or (
              abort ''
                Could not find option ${attrName} in the perSystem module. It is required to declare such an option whenever transposition.<name> is defined (and in this instance <name> is ${attrName}).
              ''))
            config.allSystems
        )
        config.transposition;

    perInput =
      system: flake:
      mapAttrs
        (attrName: attrConfig:
          flake.${attrName}.${system} or (
            throw (perInputAttributeError { inherit system flake attrName attrConfig; })
          )
        )
        config.transposition;

    perSystem = {
      options =
        mapAttrs
          (k: v: lib.mkOption { })
          (filterAttrs
            (k: v: v.adHoc)
            config.transposition
          );
    };
  };
}
