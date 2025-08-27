#!/usr/bin/env bash
set -euo pipefail

# ログをファイルにも吐く
LOG_DIR="$HOME/vrchat-dev"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/install.log") 2>&1

#-------------------------------------------------
# 変数
#-------------------------------------------------
UNITY_VERSION="2022.3.22f1"
PROJ_DIR="$HOME/vrchat-dev/project"
PKGS=(vrc_sdk3-worlds vrc_sdk3-avatars udonsharp)
MCP_DIR="$HOME/vrchat-dev/unity-mcp"

# Ubuntu を非対話モードに
export DEBIAN_FRONTEND=noninteractive

#-------------------------------------------------
# Unity Hub ──────────────────────────────────────
#-------------------------------------------------
if ! command -v unityhub &>/dev/null; then
  echo "[*] Installing Unity Hub…"
  # GPG key を keyrings へ保存（apt-key 非推奨回避）
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

#-------------------------------------------------
# Unity Editor (headless) ────────────────────────
#-------------------------------------------------
if ! unityhub -- --headless editors -i | grep -q "$UNITY_VERSION"; then
  echo "[*] Installing Unity Editor $UNITY_VERSION…"
  # 変更セット ID を取得
  CHANGESET=$(unityhub -- --headless editors -a \
               | awk -v v="$UNITY_VERSION" '$1==v{print $2;exit}')
  if [[ -z "$CHANGESET" ]]; then
    echo "[!] Unity Hub が $UNITY_VERSION を見つけられません"
    exit 1
  fi

  # 必要最小限モジュールのみ
  unityhub -- --headless install \
    --version "$UNITY_VERSION" \
    --changeset "$CHANGESET" \
    --module linux-il2cpp
else
  echo "[=] Unity Editor $UNITY_VERSION 既に存在"
fi

#-------------------------------------------------
# vrc-get ────────────────────────────────────────
#-------------------------------------------------
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

#-------------------------------------------------
# UnityMCP (Node.js LTS 同梱ビルド) ──────────────
#-------------------------------------------------
if [[ ! -d "$MCP_DIR/UnityMCPforUbuntu22.04" ]]; then
  echo "[*] Cloning UnityMCP…"
  mkdir -p "$MCP_DIR"
  git clone --depth=1 \
    https://github.com/KAFKA2306/UnityMCPforUbuntu22.04.git \
    "$MCP_DIR/UnityMCPforUbuntu22.04"
else
  echo "[=] UnityMCP 既にクローン済み"
fi

# Node.js
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

#-------------------------------------------------
# プロジェクトおよび SDK / UdonSharp ──────────────
#-------------------------------------------------
mkdir -p "$PROJ_DIR"
for pkg in "${PKGS[@]}"; do
  if ! vrc-get --project "$PROJ_DIR" list | grep -q "$pkg"; then
    echo "[*] vrc-get install $pkg"
    vrc-get --project "$PROJ_DIR" install "$pkg"
  fi
done

#-------------------------------------------------
# 完了
#-------------------------------------------------
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
