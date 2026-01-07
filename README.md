# Setup Zig Action

Installs Zig compiler in GitHub Actions runner.

## Inputs

- `version` (optional): Zig version. Default: latest stable. Use `dev` or `master` for latest development version.

## Example usage

```yaml
uses: jetsung/setup-zig@v1
with:
  version: "0.15.2"
```

## Install Zig in Desktop or Server
```bash
curl -L https://raw.githubusercontent.com/jetsung/setup-zig/main/install.sh | bash

# or with version
curl -L https://raw.githubusercontent.com/jetsung/setup-zig/main/install.sh | bash -s -- 0.15.2
```

## Links

- [Official Website](https://ziglang.org/)
- [Downloads](https://ziglang.org/download/)
- [Documentation](https://ziglang.org/learn/overview/)
