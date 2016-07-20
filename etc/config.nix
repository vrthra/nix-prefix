pkgs:
{
  packageOverrides = self: {
    nixUnstable = self.nixUnstable.override {
      storeDir = "BASE/nix/store";
      stateDir = "BASE/nix/var";
    };
  };
  allowUnfree = true;
  allowBroken = true;
}

