#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  make \
  swi-prolog \
  curl \
  xz-utils \
  ca-certificates

# Typst 0.15.0 이상 설치 (공식 설치 스크립트 사용)
if ! command -v typst >/dev/null 2>&1; then
  curl -fsSL https://typst.community/typst-install/install.sh | sh
fi

# PATH 반영 (설치 스크립트 기본 경로)
if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
  export PATH="$HOME/.local/bin:$PATH"
fi

# typst 버전 체크 (0.15.0 이상 요구)
if command -v typst >/dev/null 2>&1; then
  INSTALLED="$(typst --version | awk '{print $2}')"
  REQUIRED="0.15.0"
  if [ "$(printf '%s\n' "$REQUIRED" "$INSTALLED" | sort -V | head -n1)" != "$REQUIRED" ]; then
    echo "Typst version $INSTALLED is lower than required $REQUIRED"
    exit 1
  fi
else
  echo "Typst installation failed"
  exit 1
fi

# sha256sum, make, swipl 확인
command -v sha256sum >/dev/null 2>&1 || (echo "sha256sum not found" && exit 1)
command -v make >/dev/null 2>&1 || (echo "make not found" && exit 1)
command -v swipl >/dev/null 2>&1 || (echo "SWI Prolog (swipl) not found" && exit 1)

echo "✅ Devcontainer setup complete"
make --version | head -n1
sha256sum --version | head -n1
swipl --version
typst --version
