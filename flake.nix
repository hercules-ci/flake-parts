{
  description = "Flake basics described using the module system";

  inputs = {
    nixpkgs-lib.url = "https://github.com/NixOS/nixpkgs/archive/50eb7ecf4cd0a5756d7275c8ba36790e5bd53e33.tar.gz"; # 58a1abdbae3217ca6b702f03d3b35125d88a2994 /lib from nixos-unstable
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
