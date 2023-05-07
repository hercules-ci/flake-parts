{inputs, ...}: {
  options.perSystem = mkPerSystemOption ({ pkgs, system, ... }: {
    imports = [
      "${inputs.nixpkgs}/nixos/modules/misc/nixpkgs.nix"
    ];
    nixpkgs.hostPlatform = system;
  });
}