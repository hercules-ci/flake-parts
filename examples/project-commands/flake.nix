{
  description = "Description for the project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    mission-control.url = "github:Platonic-Systems/mission-control";
    flake-root.url = "github:srid/flake-root";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.mission-control.flakeModule
        inputs.flake-root.flakeModule
      ];
      systems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [ avro-tools ];
          inputsFrom = [ config.mission-control.devShell config.flake-root.devShell ];
        };
        mission-control = {
          wrapperName = "run";
          scripts = {
            build = {
              description = "convert files from .avdl to .avsc";
              exec = ''
                avro-tools idl2schemata "$FLAKE_ROOT/Hello.avdl" .
              '';
              category = "Development";
            };
          };
        };
      };
    };
}
