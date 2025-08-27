#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="$HOME/vrchat-dev"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/install.log") 2>&1

UNITY_VERSION="2022.3.22f1"
PROJ_DIR="$HOME/vrchat-dev/project"
PKGS=(vrc_sdk3-worlds vrc_sdk3-avatars udonsharp)
MCP_DIR="$HOME/vrchat-dev/unity-mcp"

export DEBIAN_FRONTEND=noninteractive

if ! command -v unityhub &>/dev/null; then
  echo "[*] Installing Unity Hub…"
  sudo mkdir -p /usr/share/keyrings
  curl -fsSL https://hub.unity3d.com/linux/keys/public \
    | sudo gpg --dearmor -o /usr/share/keyrings/unityhub.gpg

  echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/unityhub.gpg] \
https://hub.unity3d.com/linux/repos/deb stable main' \
    | sudo tee /etc/apt/sources.list.d/unityhub.list >/dev/null

  sudo apt-get update
  sudo apt-get install -y unityhub
else
  echo "[=] Unity Hub 既にインストール済み"
fi

if ! unityhub -- --headless editors -i | grep -q "$UNITY_VERSION"; then
  echo "[*] Installing Unity Editor $UNITY_VERSION…"
  
  AVAILABLE_VERSIONS=$(unityhub -- --headless editors -a 2>/dev/null || echo "")
  
  if echo "$AVAILABLE_VERSIONS" | grep -q "^$UNITY_VERSION"; then
    CHANGESET=$(echo "$AVAILABLE_VERSIONS" | awk -v v="$UNITY_VERSION" '$1==v{print $2;exit}')
  else
    echo "[!] $UNITY_VERSION not available. Available versions:"
    echo "$AVAILABLE_VERSIONS" | head -5
    LATEST_2022=$(echo "$AVAILABLE_VERSIONS" | grep "^2022\.3\." | head -1)
    if [[ -n "$LATEST_2022" ]]; then
      UNITY_VERSION=$(echo "$LATEST_2022" | awk '{print $1}')
      CHANGESET=$(echo "$LATEST_2022" | awk '{print $2}')
      echo "[*] Using $UNITY_VERSION instead"
    else
      echo "[!] No Unity 2022.3.x version available"
      exit 1
    fi
  fi

  if [[ -z "$CHANGESET" ]]; then
    echo "[!] Could not determine changeset for $UNITY_VERSION"
    exit 1
  fi

  unityhub -- --headless install \
    --version "$UNITY_VERSION" \
    --changeset "$CHANGESET" \
    --module linux-il2cpp
else
  echo "[=] Unity Editor $UNITY_VERSION 既に存在"
fi

if ! command -v vrc-get &>/dev/null; then
  echo "[*] Installing vrc-get…"
  tmp=$(mktemp -d)
  curl -sL "$(curl -sL \
    https://api.github.com/repos/lox9973/vrc-get/releases/latest \
      | grep linux-x64 | grep browser_download_url \
      | cut -d'"' -f4)" -o "$tmp/vrc-get.tar.gz"

  tar -xf "$tmp/vrc-get.tar.gz" -C "$tmp"
  sudo install -m755 "$tmp/vrc-get" /usr/local/bin
  rm -rf "$tmp"
else
  echo "[=] vrc-get 既にインストール済み"
fi

if [[ ! -d "$MCP_DIR/UnityMCPforUbuntu22.04" ]]; then
  echo "[*] Cloning UnityMCP…"
  mkdir -p "$MCP_DIR"
  git clone --depth=1 \
    https://github.com/KAFKA2306/UnityMCPforUbuntu22.04.git \
    "$MCP_DIR/UnityMCPforUbuntu22.04"
else
  echo "[=] UnityMCP 既にクローン済み"
fi

if ! command -v npm &>/dev/null; then
  echo "[*] Installing Node.js LTS…"
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

pushd "$MCP_DIR/UnityMCPforUbuntu22.04/unity-mcp-server" >/dev/null
  echo "[*] npm ci && npm run build"
  npm ci --omit=dev
  npm run build
popd >/dev/null

mkdir -p "$PROJ_DIR"
for pkg in "${PKGS[@]}"; do
  if ! vrc-get --project "$PROJ_DIR" list | grep -q "$pkg"; then
    echo "[*] vrc-get install $pkg"
    vrc-get --project "$PROJ_DIR" install "$pkg"
  fi
done

cat <<EOF

========================================
  SETUP COMPLETE ✨
========================================
Unity Hub      : unityhub &
Headless Editor: $UNITY_VERSION
Project        : $PROJ_DIR
UnityMCP srv   : $MCP_DIR/UnityMCPforUbuntu22.04/unity-mcp-server

次の手順
------------------------------------------------
1) Unity Hub を起動し、初回のみ
   ・Unity アカウントで sign-in
   ・License (Personal) のアクティベート
2) Hub でプロジェクト $PROJ_DIR を開く
3) MCP サーバーを別端末で
     cd \$MCP_DIR/UnityMCPforUbuntu22.04/unity-mcp-server
     node dist/index.js
   として起動
4) 好きなワールド／アバター開発を開始！
EOF
