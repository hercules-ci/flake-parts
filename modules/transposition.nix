{ config, lib, flake-parts-lib, ... }:

let
  inherit (lib)
    filterAttrs
    mapAttrs
    mkOption
    types
    ;
  inherit (flake-parts-lib)
    mkSubmoduleOptions
    mkPerSystemOption
    ;
in
{
  options = {
    transposition = lib.mkOption {
      description = ''
        A helper that defines transposed attributes in the flake outputs.

        Transposition is the operation that swaps the indices of a data structure.
        Here it refers specifically to the transposition between

        <literal>
          perSystem: .''${system}.''${attribute}
          outputs:   .''${attribute}.''${system}
        </literal>

        It also defines the reverse operation in <option>perInput</option>.
      '';
      type =
        types.lazyAttrsOf
          (types.submoduleWith { modules = [ ]; });
    };
  };

  config = {
    flake =
      lib.mapAttrs
        (attrName: attrConfig:
          mapAttrs
            (system: v: v.${attrName})
            config.allSystems
        )
        config.transposition;

    perInput =
      system: flake:
      mapAttrs
        (attrName: attrConfig: flake.${attrName}.${system})
        (filterAttrs
          (attrName: attrConfig: flake?${attrName}.${system})
          config.transposition
        );
  };
}
