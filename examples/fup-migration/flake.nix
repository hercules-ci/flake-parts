{
  description = "FUP migration POC — multi-channel, hosts, auto-registry in flake-parts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";

    # Uncomment to test darwin:
    # nix-darwin.url = "github:LnL7/nix-darwin";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];

      # Import the FUP migration module
      imports = [ ./fup-module.nix ];

      # ====================================================================
      # ╔══════════════════════════════════════════════════════════════════╗
      # ║  FUP-style configuration via flake-parts module options          ║
      # ╚══════════════════════════════════════════════════════════════════╝
      # ====================================================================
      fup = {
        # ------------------------------------------------------------------
        # 1. MULTI-CHANNEL — declare multiple nixpkgs versions
        # ------------------------------------------------------------------
        channels = {
          # Default channel, used by any host that doesn't override channelName
          nixpkgs = {
            input = inputs.nixpkgs;
            # Per-channel nixpkgs config
            config.allowUnfree = false;
            # Channel-specific overlays — receives ALL channel pkgs for
            # cross-channel references (e.g., import from unstable)
            overlaysBuilder = allPkgs: [
              (final: prev: {
                inherit (allPkgs.stable) hello;
              })
            ];
          };

          # A stable channel with different config
          stable = {
            input = inputs.nixpkgs-stable;
            config.allowUnfree = true;
            # To test source patching, uncomment:
            # patches = [ ./fix-python.patch ];
          };
        };

        # ------------------------------------------------------------------
        # 2. OVERLAYS — applied to ALL channels
        # ------------------------------------------------------------------
        sharedOverlays = [
          (final: prev: {
            hello-fup = final.hello.overrideAttrs (old: {
              pname = "${old.pname}-fup";
            });
          })
        ];

        # ------------------------------------------------------------------
        # 3. HOST ABSTRACTION — declarative machines with builder dispatch
        # ------------------------------------------------------------------
        hostDefaults = {
          system = "x86_64-linux";
          channelName = "nixpkgs";
          # output = "nixosConfigurations";  # default
          # To use darwin instead:
          # output = "darwinConfigurations";
          # builder = inputs.nix-darwin.lib.darwinSystem;
        };

        hosts = {
          # Reverse-DNS naming:
          #   "com.example.server" → hostname: "server", domain: "example.com"
          "com.example.server" = {
            system = "x86_64-linux";
            modules = [
              ({ pkgs, ... }: {
                environment.systemPackages = [ pkgs.hello-fup ];
              })
            ];
          };

          # Override channel per-host — uses stable nixpkgs
          "com.example.laptop" = {
            system = "x86_64-linux";
            channelName = "stable";
          };
        };

        # ------------------------------------------------------------------
        # 4. AUTO-REGISTRY — generate nix.registry / nix.nixPath
        #    (These generate NixOS module fragments added to each host)
        # ------------------------------------------------------------------
        autoRegistry = true;
        autoNixPath = true;

        # ------------------------------------------------------------------
        # bonus: auto-detect extra nixpkgs inputs
        # ------------------------------------------------------------------
        autoDetectChannels = false;
      };

      # ====================================================================
      # Everything else works normally alongside fup options
      # ====================================================================
      perSystem = { pkgs, fupChannels, system, ... }: {
        # ── devShells ──
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [ nix nixpkgs-fmt ];
          shellHook = ''
            echo "Channels available: ${toString (builtins.attrNames fupChannels)}"
            if fupChannels != {}; then
              echo "  nixpkgs version: ${fupChannels.nixpkgs.lib.version}"
              echo "  stable version:  ${fupChannels.stable.lib.version}"
            fi
          '';
        };

        # ── packages ──
        packages.hello-from-unstable = pkgs.hello;
        packages.hello-from-stable = fupChannels.stable.hello;

        # ── apps ──
        apps.show-channels = {
          type = "app";
          program = toString (pkgs.writeShellScript "show-channels" ''
            echo "Channel versions for ${system}:"
            echo "  nixpkgs: ${fupChannels.nixpkgs.lib.version or "N/A"}"
            echo "  stable:  ${fupChannels.stable.lib.version or "N/A"}"
          '');
        };
      };
    };
}
