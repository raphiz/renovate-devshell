{
  outputs = {...}: {
    modules.default = import ./module.nix;
  };
}
