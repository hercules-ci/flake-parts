{
  description = "Flake basics described using the module system";

  inputs = {
    # nix-community/nixpkgs.lib is equivalent to nixpkgs?dir=lib, except it is
    # decoupled from its parent directory.
    #
    # You may use nixpkgs?dir=lib or even nixpkgs as an input instead, using follows.
    # See https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#flake-inputs
    #
    # Ideally fetching a subtree would be an builtins.fetchTree (aka flake inputs)
    # feature, but that has not been implemented yet, and while take a while to
    # be widely available.
    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
  };

  outputs = { self, nixpkgs-lib, ... }: {
    lib = import ./lib.nix { inherit (nixpkgs-lib) lib; };
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
