{
  description = "The dev flake to set up the devShell. It dogfoods modules provided by the public flake";

  inputs = {
    public.url = "path:..";
    nixpkgs.follows = "public/nixpkgs";
    flake-parts.follows = "public/flake-parts";
  };

  outputs = { public, flake-parts, nixpkgs, self, ... }@inputs: flake-parts.lib.mkFlake { inherit inputs; } public.flakeModules.dev;
}
