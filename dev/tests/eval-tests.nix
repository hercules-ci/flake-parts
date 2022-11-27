rec {
  f-p = builtins.getFlake (toString ../..);
  f-p-lib = f-p.lib;

  inherit (f-p-lib) mkFlake;
  inherit (f-p.inputs.nixpkgs-lib) lib;

  pkg = system: name: derivation {
    name = name;
    builder = "no-builder";
    system = system;
  };

  empty = mkFlake
    { self = { }; }
    {
      systems = [ ];
    };

  example1 = mkFlake
    { self = { }; }
    {
      systems = [ "a" "b" ];
      perSystem = { system, ... }: {
        packages.hello = pkg system "hello";
      };
    };

  runTests = ok:

    assert empty == {
      apps = { };
      checks = { };
      darwinModules = { };
      devShells = { };
      formatter = { };
      legacyPackages = { };
      nixosConfigurations = { };
      nixosModules = { };
      overlays = { };
      packages = { };
    };

    assert example1 == {
      apps = { a = { }; b = { }; };
      checks = { a = { }; b = { }; };
      darwinModules = { };
      devShells = { a = { }; b = { }; };
      formatter = { };
      legacyPackages = { a = { }; b = { }; };
      nixosConfigurations = { };
      nixosModules = { };
      overlays = { };
      packages = {
        a = { hello = pkg "a" "hello"; };
        b = { hello = pkg "b" "hello"; };
      };
    };

    ok;

  result = runTests "ok";
}
