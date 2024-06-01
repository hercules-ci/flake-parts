{
  description = "Flake basics described using the module system";

  inputs = {
    nixpkgs-lib.url = "https://github.com/NixOS/nixpkgs/archive/eb9ceca17df2ea50a250b6b27f7bf6ab0186f198.tar.gz"; # ad57eef4ef0659193044870c731987a6df5cf56b /lib from nixos-unstable
  };

  outputs = { nixpkgs-lib, ... }: {
    lib = import ./lib.nix {
      inherit (nixpkgs-lib) lib;
      # Extra info for version check message
      revInfo =
        if nixpkgs-lib?rev
        then " (nixpkgs-lib.rev: ${nixpkgs-lib.rev})"
        else "";
    };
    templates = {
      default = {
        path = ./template/default;
        description = ''
          A minimal flake using flake-parts.
        '';
      };
      multi-module = {
        path = ./template/multi-module;
        description = ''
          A minimal flake using flake-parts.
        '';
      };
      unfree = {
        path = ./template/unfree;
        description = ''
          A minimal flake using flake-parts importing nixpkgs with the unfree option.
        '';
      };
    };
    flakeModules = {
      easyOverlay = ./extras/easyOverlay.nix;
      flakeModules = ./extras/flakeModules.nix;
    };
  };

}
