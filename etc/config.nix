pkgs:
{
  packageOverrides = self: {
    nixUnstable = self.nixUnstable.override {
      storeDir = "/scratch/gopinatr/nix/store";
      stateDir = "/scratch/gopinatr/nix/var";
    };
  };
  allowUnfree = true;
  allowBroken = true;
}

