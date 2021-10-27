{ lib, ... }: {
  options.self = lib.mkOption {
    description = "The current flake.";
    type = type.lazyAttrsOf type.unspecified;
  };
}
