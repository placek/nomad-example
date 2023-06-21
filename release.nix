{ pkgs ? import <nixpkgs> { } }:

let
  wdir = "app";
  gems = pkgs.bundlerEnv {
    inherit (pkgs) ruby;
    name = "nomad-app";
    gemdir = ./.;
  };
  project = pkgs.stdenv.mkDerivation {
    name = "nomad-app-src";
    src = ./.;
    buildPhase = "true";
    installPhase = ''
      mkdir -p $out/${wdir}
      cp -r $src/* $out/${wdir}
    '';
  };
  packages = with pkgs; [
    busybox
    ruby
    gems
    project
  ];
  nomad_1_3_5 = (import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/ee01de29d2f58d56b1be4ae24c24bd91c5380cea.tar.gz";
  }) {}).nomad;
  consul_1_13_1 = (import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/ee01de29d2f58d56b1be4ae24c24bd91c5380cea.tar.gz";
  }) {}).consul;
in
{
  image = pkgs.dockerTools.buildImage {
    name = "silquenarmo/nomad-app";
    tag = "latest";
    contents = packages;
    config = {
      WorkingDir = "/${wdir}";
    };
  };

  shell = pkgs.mkShell {
    buildInputs = [
      nomad_1_3_5
      consul_1_13_1
      pkgs.bundix
    ] ++ packages;
  };
}
