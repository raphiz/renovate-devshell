{
  options,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkEnableOption
    mkPackageOption
    mkOption
    types
    mkIf
    ;
  json = pkgs.formats.json {};
  cfg = config.renovate;
  generateValidatedConfig = name: value:
    pkgs.callPackage (
      {
        runCommand,
        jq,
      }:
        runCommand name
        {
          nativeBuildInputs = [
            jq
            cfg.package
          ];
          value = builtins.toJSON value;
          passAsFile = ["value"];
          preferLocalBuild = true;
        }
        ''
          jq . "$valuePath"> $out
          renovate-config-validator $out
        ''
    ) {};
  generateConfig =
    if cfg.validateSettings
    then generateValidatedConfig
    else json.generate;
in {
  options.renovate = {
    enable = mkEnableOption "renovate";
    package = mkPackageOption pkgs "renovate" {};

    validateSettings = mkOption {
      type = types.bool;
      default = true;
      description = "Wether to run renovate's config validator on the built configuration.";
    };

    settings = mkOption {
      type = json.type;
      default = {};
      example = {
        platform = "gitea";
        endpoint = "https://git.example.com";
        gitAuthor = "Renovate <renovate@example.com>";
      };
      description = ''Renovate's global configuration.'';
    };
  };

  config = let
    renovatePreview = pkgs.callPackage ./renovate-preview.nix {
      renovate = cfg.package;
    };
    configFile = generateConfig "renovate-config.json" cfg.settings;
  in
    mkIf cfg.enable {
      # add package to devenv.sh
      ${
        if (options ? devenv && options ? packages)
        then "packages"
        else null
      } = [cfg.package renovatePreview];
      ${
        if (options ? devenv && options ? env)
        then "env"
        else null
      } = {RENOVATE_CONFIG_FILE = configFile;};

      # Add command in devenv.nix
      ${
        if (options ? devshell && options ? commands)
        then "commands"
        else null
      } = [
        {
          package = cfg.package;
          help = "Renovate";
        }
        {
          package = renovatePreview;
          help = "Renovate Preview";
        }
      ];
      ${
        if (options ? devshell && options ? env)
        then "env"
        else null
      } = [
        {
          name = "RENOVATE_CONFIG_FILE";
          value = configFile;
        }
      ];
    };
}
