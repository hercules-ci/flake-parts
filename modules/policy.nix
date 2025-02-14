{ lib, ... }:
{
  options = {
    policy.telemetry.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      # This is no legalese, but it's a start. If you expect flake.parts to be lenient, you'll be disappointed.
      # We'll develop a more formal policy over time.
      description = ''
        If `true`, allow flake-parts modules to cause telemetry data to be sent to their maintainers.

        The core options and core modules provided by flake-parts will never send telemetry data, and would be largely incapable of doing so anyway.

        Please report any cases of non-compliance with this option kindly to the module maintainer first, and to [the `flake.parts-website` issue tracker](https://github.com/hercules-ci/flake.parts-website/issues) if insufficient action is taken by the maintainer.

        `devShells` implementations should consider setting `DO_NOT_TRACK=1` in their environment when `false`. See [consoleDoNotTrack.com](https://consoledonottrack.com).

        If you wish to receive telemetry data from a module you provide, plenty of users are willing to help you out if you ask them politely, and make it easy by providing an example of how to enable the option as part of your installation example.
        Remember that your role is not to make it easy for yourself, but to make it easy for others to help you, based on a relationship of trust and mutual respect.
        Repeated small effects build to a large impact over time. Thank you for being a constructive member of society.
      '';
    };
  };
}
