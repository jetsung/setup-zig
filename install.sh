#!/usr/bin/env bash

# 启用严格模式（根据 DEBUG 环境变量决定是否打印命令）
if [[ -n "${DEBUG:-}" ]]; then
    set -eux
else
    set -euo pipefail
fi

USER_ID="$(id -u)"

sudo_exec() {
    if [[ "$USER_ID" -ne 0 && "${PACKAGES_DIR:-}" != "$HOME"* ]]; then
        sudo "$@"
    else
        "$@"
    fi
}

main() {
  if [[ -n "${1:-}" ]]; then
    VERSION_INPUT="$1"
  fi

  VERSION_INPUT="${VERSION_INPUT:-}"

  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m)"

  case "$ARCH" in
    x86_64) ARCH="x86_64" ;;
    aarch64 | arm64) ARCH="aarch64" ;;
    *) echo "Unsupported architecture: $ARCH" && exit 1 ;;
  esac

  if [[ -z "$VERSION_INPUT" ]]; then
    VERSION=$(curl -s https://ziglang.org/download/index.json | \
                jq -r 'keys 
                  | map(select(.!="master")) 
                  | sort_by(. | split(".") 
                  | map(tonumber)) 
                  | reverse 
                  | .[0]
                ')
  elif [[ "$VERSION_INPUT" == "dev" || "$VERSION_INPUT" == "master" ]]; then
    VERSION="master"
  else
    VERSION="$VERSION_INPUT"
  fi

  if [[ -n "${2:-}" ]]; then
    PACKAGES_DIR="$2"
  elif [[ "$USER_ID" -eq 0 ]]; then
    PACKAGES_DIR="/usr/local/zig"
  else
    PACKAGES_DIR="$HOME/.local/zig"
  fi

  sudo_exec mkdir -p "$PACKAGES_DIR"

  if [[ "$VERSION" == "master" ]]; then
    URL=$(curl -s https://ziglang.org/download/index.json \
      | jq -r ".master.\"${ARCH}-${OS}\".tarball")
  else
    URL=$(curl -s https://ziglang.org/download/index.json \
      | jq -r ".\"$VERSION\".\"${ARCH}-${OS}\".tarball")
  fi

  if [[ -z "$URL" || "$URL" == "null" ]]; then
    echo "Error: Could not find download URL for Zig $VERSION ($ARCH-$OS)."
    exit 1
  fi

  if ! curl -Isf "$URL" > /dev/null; then
    echo "Error: Download URL is invalid or unreachable: $URL"
    exit 1
  fi

  # echo "Downloading Zig $VERSION for $ARCH-$OS from $URL"
  curl -fsSL "$URL" | sudo_exec tar xJC "$PACKAGES_DIR" --strip-components=1

  if [[ -n "${GITHUB_PATH:-}" ]]; then
    echo "$PACKAGES_DIR" >> "$GITHUB_PATH"
  else
    if [[ "$PACKAGES_DIR" == "$HOME"* && "$USER_ID" -ne 0 ]]; then
      # Local install for non-root user: use local profile
      # Update zsh if it exists
      if [[ -f "$HOME/.zshrc" ]]; then
        echo "export PATH=$PACKAGES_DIR:\$PATH" >> "$HOME/.zshrc"
        echo "Added Zig to PATH in $HOME/.zshrc"
      fi

      # Update bash/profile
      PROFILE_FILE="$HOME/.profile"
      if [[ -f "$HOME/.bashrc" ]]; then
        PROFILE_FILE="$HOME/.bashrc"
      elif [[ -f "$HOME/.bash_profile" ]]; then
        PROFILE_FILE="$HOME/.bash_profile"
      fi
      echo "export PATH=$PACKAGES_DIR:\$PATH" >> "$PROFILE_FILE"
      echo "Added Zig to PATH in $PROFILE_FILE"
    else
      # System install or root user: use /etc/profile
      if [[ "$USER_ID" -ne 0 ]]; then
        echo "export PATH=$PACKAGES_DIR:\$PATH" | sudo tee -a /etc/profile > /dev/null
      else
        echo "export PATH=$PACKAGES_DIR:\$PATH" >> /etc/profile
      fi
      echo "Added Zig to PATH in /etc/profile"
    fi
    export PATH="$PACKAGES_DIR:$PATH"
    echo "Zig $VERSION installed successfully."
    "$PACKAGES_DIR/zig" version
  fi
}

main "$@"