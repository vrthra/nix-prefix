#!/usr/bin/env nix-shell
#! nix-shell --pure --run "env i_fcolor=red zsh" env.nix
with import <nixpkgs> {};
stdenv.mkDerivation rec {
  name = "env";
  env = buildEnv { name = name; paths = buildInputs; };
  builder = builtins.toFile "builder.sh" "source $stdenv/setup; ln -s $env $out";

  buildInputs = [
    perl
    curl
    gitFull
    vim
    less
    (rWrapper.override {
     packages = with rPackages; [
     ggplot2
     xtable
     dplyr
     scales
     reshape2
     mgcv
     knitr
     ezknitr
     tidyr
     broom
     ];
     })
  (texlive.combine {
   inherit (texlive)
      scheme-small
      algorithms cm-super relsize framed placeins boxedminipage comment
      blindtext collection-fontsrecommended
      IEEEtran;
   })
  ];

  # Customizable development shell setup with at last SSL certs set
  shellHook = ''
    export PS1="$SHLVL\[\e[33m\]|\[\e[m\] "
    export R_LIBS=~/.R/library/
    TERM=xterm
  '';
}

