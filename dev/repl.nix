# convenience for loading into nix repl
let self = builtins.getFlake (toString ./.);
in self // { inherit self; }
