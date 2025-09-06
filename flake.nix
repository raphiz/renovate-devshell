{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
  };
  outputs = {
    nixpkgs,
    systems,
    ...
  }: let
    eachSystem = nixpkgs.lib.genAttrs (import systems);
  in {
    modules.default = import ./module.nix;
    packages = eachSystem (
      system: {
        renovate-preview = nixpkgs.legacyPackages.${system}.callPackage ./renovate-preview.nix {};
      }
    );
  };
}
