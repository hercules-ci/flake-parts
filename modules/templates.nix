{ lib, ... }:
let
  template = lib.types.submodule {
    options = {
      path = lib.mkOption {
        description = "The path of the directory to be copied.";
        example = ./rust;
        type = lib.types.path;
      };

      description = lib.mkOption {
        default = "";
        description = "A one-line description of the template, in CommonMark syntax.";
        example = "A simple Rust/Cargo project.";
        type = lib.types.str;
      };

      welcomeText = lib.mkOption {
        default = "";
        description = "A block of markdown text to display when a user initializes a new flake based on this template.";
        type = lib.types.str;

        example = ''
          # Simple Rust/Cargo Template

          ## Intended usage
          The intended usage of this flake is...

          ## More info
          - [Rust language](https://www.rust-lang.org/)
          - [Rust on the NixOS Wiki](https://wiki.nixos.org/wiki/Rust)
          - ...
        '';
      };
    };
  };
in
{
  options.flake.templates = lib.mkOption {
    default = { };
    description = "An attribute set of project templates.";
    type = lib.types.attrsOf template;
  };
}
