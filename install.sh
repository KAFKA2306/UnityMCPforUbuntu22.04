#!/usr/bin/env bash
set -euo pipefail

# ログ
LOG_DIR="$HOME/vrchat-dev"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/install.log") 2>&1

export DEBIAN_FRONTEND=noninteractive

# 設定
TARGET_VERSIONS=(2022.3.20f1 2022.3.17f1 2022.3.15f1 2022.3.6f1)
PROJ_DIR="$HOME/vrchat-dev/project"
MCP_DIR="$HOME/vrchat-dev/unity-mcp"
PKGS=(vrc_sdk3-worlds vrc_sdk3-avatars udonsharp)

# 依存ツール（xvfb で仮想Xを用意）
echo "[*] Installing prerequisites…"
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg xvfb dbus
if ! sudo apt-get install -y libasound2; then
  sudo apt-get install -y libasound2t64
fi

# Unity Hub インストール
if ! command -v unityhub &>/dev/null; then
  echo "[*] Installing Unity Hub…"
  sudo mkdir -p /usr/share/keyrings
  curl -fsSL https://hub.unity3d.com/linux/keys/public \
    | sudo gpg --dearmor -o /usr/share/keyrings/unityhub.gpg
  echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/unityhub.gpg] https://hub.unity3d.com/linux/repos/deb stable main' \
    | sudo tee /etc/apt/sources.list.d/unityhub.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y unityhub
else
  echo "[=] Unity Hub already installed"
fi

# Unity Hub ラッパー（xvfb-run + headless + errors）
HUB() {
  dbus-run-session -- \
    xvfb-run --auto-servernum --server-args='-screen 0 1280x1024x24' \
      unityhub --headless --errors "$@"
}

# 対応 Unity Editor の導入（--changeset auto + linux-il2cpp）
echo "[*] Installing VRChat-ready Unity Editors…"
INSTALLED=false
UNITY_VERSION=""

for v in "${TARGET_VERSIONS[@]}"; do
  echo "[*] Trying Unity $v ..."
  # changeset は --changeset auto で自動解決
  if HUB install --version "$v" --changeset auto --module linux-il2cpp; then
    INSTALLED=true
    UNITY_VERSION="$v"
    echo "[*] Installed Unity $v"
    break
  else
    echo "[!] Failed $v, trying next…"
  fi
done

if ! $INSTALLED; then
  echo "[!] All target versions failed to install"
  exit 1
fi

# vrc-get インストール（最新リリースの linux-x64 を取得）
if ! command -v vrc-get &>/dev/null; then
  echo "[*] Installing vrc-get…"
  TMP=$(mktemp -d)
  curl -sL "$(curl -sL https://api.github.com/repos/vrc-get/vrc-get/releases/latest \
    | grep -Eo 'https[^"]+linux-x64[^"]+' | head -n1)" -o "$TMP/vrc-get.tar.gz"
  tar -xf "$TMP/vrc-get.tar.gz" -C "$TMP"
  # 展開物が vrc-get か vrc-get-linux-x64 かを吸収
  BIN_PATH="$(find "$TMP" -maxdepth 1 -type f -name 'vrc-get*' | head -n1)"
  sudo install -m755 "$BIN_PATH" /usr/local/bin/vrc-get
  rm -rf "$TMP"
else
  echo "[=] vrc-get already installed"
fi

# UnityMCP クローン
if [[ ! -d "$MCP_DIR/UnityMCPforUbuntu22.04" ]]; then
  echo "[*] Cloning UnityMCP…"
  mkdir -p "$MCP_DIR"
  git clone --depth=1 https://github.com/KAFKA2306/UnityMCPforUbuntu22.04.git \
    "$MCP_DIR/UnityMCPforUbuntu22.04"
else
  echo "[=] UnityMCP already cloned"
fi

# Node.js（LTS）導入と MCP サーバービルド
if ! command -v npm &>/dev/null; then
  echo "[*] Installing Node.js LTS…"
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt-get install -y nodejs
else
  echo "[=] Node.js already installed"
fi

pushd "$MCP_DIR/UnityMCPforUbuntu22.04/unity-mcp-server" >/dev/null
  echo "[*] npm ci && npm run build"
  npm ci --omit=dev
  npm run build
popd >/dev/null

# VRChat SDK (VPM) をプロジェクトへ導入
mkdir -p "$PROJ_DIR"
for pkg in "${PKGS[@]}"; do
  if ! vrc-get --project "$PROJ_DIR" list | grep -q "$pkg"; then
    echo "[*] vrc-get install $pkg"
    vrc-get --project "$PROJ_DIR" install "$pkg"
  else
    echo "[=] $pkg already in project"
  fi
done

cat <<EOF

========================================
  SETUP COMPLETE ✨
========================================
Unity Hub      : unityhub (GUI sign-in required once)
Editor Version : $UNITY_VERSION
Project        : $PROJ_DIR
UnityMCP srv   : $MCP_DIR/UnityMCPforUbuntu22.04/unity-mcp-server

Next steps
------------------------------------------------
1) Start Unity Hub GUI, sign in and activate Personal license (first time only)
2) Open project at: $PROJ_DIR
3) In another terminal:
     cd $MCP_DIR/UnityMCPforUbuntu22.04/unity-mcp-server
     node dist/index.js
4) Start building VRChat worlds/avatars!
EOF
