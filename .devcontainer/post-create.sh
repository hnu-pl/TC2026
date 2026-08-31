#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  make \
  swi-prolog \
  curl \
  xz-utils \
  ca-certificates \
  fontconfig \
  fonts-noto-cjk \
  fonts-dejavu-core

# Hack 폰트는 저장소에 없을 수 있으므로 best-effort로 설치 (실패해도 스크립트 계속 진행)
sudo apt-get install -y --no-install-recommends fonts-hack || echo "fonts-hack 설치 불가, DejaVu Sans Mono로 폴백"

fc-cache -f

# Typst 0.15.0 이상 설치 (공식 설치 스크립트 사용)
if ! command -v typst >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/typst-community/typst-install/main/install.sh | sh
fi

# PATH 반영 (설치 스크립트 기본 경로)
if [ -d "$HOME/.typst/bin" ] && [[ ":$PATH:" != *":$HOME/.typst/bin:"* ]]; then
  echo 'export TYPST_INSTALL="$HOME/.typst"' >> "$HOME/.bashrc"
  echo 'export PATH="$TYPST_INSTALL/bin:$PATH"' >> "$HOME/.bashrc"
  export PATH="$HOME/.typst/bin:$PATH"
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

# 한글 CJK 폰트 설치 확인 (필수)
fc-list | grep -qi "Noto Sans CJK KR" || (echo "Noto Sans CJK KR not found" && exit 1)
fc-list | grep -qi "Noto Serif CJK KR" || (echo "Noto Serif CJK KR not found" && exit 1)

# 고정폭 폰트 설치 여부 로그 (Hack은 선택 사항, DejaVu Sans Mono가 최종 폴백)
fc-list | grep -qi "Hack" && echo "Hack 폰트 설치됨" || echo "Hack 폰트 없음, DejaVu Sans Mono로 폴백"
fc-list | grep -qi "DejaVu Sans Mono" || (echo "DejaVu Sans Mono not found" && exit 1)

echo "✅ Devcontainer setup complete"
make --version | head -n1
sha256sum --version | head -n1
swipl --version
typst --version
