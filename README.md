# Renovate for Nix Devshells

Run and configure [Renovate](https://github.com/renovatebot/renovate) via devshell.
This setup allows Renovate to run as an on-demand or scheduled CI job without requiring a continuously running server.

If you're using NixOS, consider the [NixOS Renovate module](https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/misc/renovate.nix), as it runs Renovate as a continuously running systemd service.

This project also includes `renovate-preview`, a wrapper around Renovate that prints pending updates in a human-readable format.

## Installation

Add this repository as a flake input:

```nix
inputs.renovate.url = "github:raphiz/renovate-devshell";
```

## Usage

Import the module into your [devenv.sh](https://devenv.sh/) or [devshell.nix](https://github.com/numtide/devshell) setup:

```nix
imports = [
  inputs.renovate.modules.default
];

renovate.enable = true;
renovate.settings = {
  # Your Renovate configuration, for example:
  # platform = "gitea";
  # endpoint = "https://git.example.com";
};
```

This setup:

- Adds the `renovate` and `renovate-preview` commands to your `$PATH`.
- Automatically sets the `RENOVATE_CONFIG_FILE` environment variable with the provided settings.

> [!NOTE]
> It's recommended to use a dedicated shell environment for Renovate to reduce the closure size for both CI jobs and local development.

Ensure your project includes a [`renovate.json`](https://docs.renovatebot.com/getting-started/installing-onboarding/#configuration-location) file.

Preview pending updates with:

```bash
renovate-preview
```

### Running Renovate in CI

To integrate Renovate into your CI system, [configure Renovate settings](https://docs.renovatebot.com/examples/self-hosting/) according to your needs.
At a minimum, configure the [platform-specific](https://docs.renovatebot.com/modules/platform/) settings.

For sensitive information such as tokens (`RENOVATE_GITHUB_COM_TOKEN`, `RENOVATE_PASSWORD`, `RENOVATE_TOKEN`), use environment variables and your CI's secret management system.

### Supported CI Systems

This approach supports any CI system, including:

- GitHub Actions
- GitLab CI/CD
- Jenkins

## `renovate-preview`

The `renovate-preview` CLI provides a simple, readable summary of available updates.
In most cases, you can run the command without additional parameters:

![Example output of renovate-preview showing updates grouped by manager and kind (major, minor, etc.)](renovate-preview.png)

For more details, run:

```bash
renovate-preview --help
```

You can run this preview script independently of the devshell module by executing:

```nix
nix run github:raphiz/renovate-devshell#renovate-preview -- --no-validate
```

## Examples

### GitHub Action

...to be done...

## Contributing

Contributions are welcome!
Feel free to open an issue or submit a pull request.
