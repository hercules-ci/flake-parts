{ hci-effects, nix, git, path }:

hci-effects.mkEffect {
  inputs = [ nix git ];
  effectScript = ''
    ann() { # announce
      printf '\n\e[34;1m%s\e[0m\n' "$*"
    }
    mkdir -p ~/.config/nix
    echo 'experimental-features = nix-command flakes' >>~/.config/nix/nix.conf
    mkdir clean
    cd clean

    ann nix flake init...
    nix -v flake init -t ${../..}

    ann pointing to local sources...

    override=(--override-input flake-parts ${../..})

    ann nix flake lock...
    nix flake lock "''${override[@]}"

    ann nix flake show...
    nix -v flake show "''${override[@]}"

    ann nix build...
    nix build . "''${override[@]}"

    ann checking result...
    readlink ./result | grep hello

    echo
    printf '\n\e[32;1m%s\e[0m\n' 'All good!'
  '';
}
