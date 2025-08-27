#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="$HOME/vrchat-dev"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/install.log") 2>&1

# === 設定セクション ===
# Unity LTS の主要バージョン（VRChat 推奨: 2022.3.x 系）
TARGET_VERSIONS=(2022.3.20f1 2022.3.17f1 2022.3.15f1 2022.3.6f1)
PROJ_DIR="$HOME/vrchat-dev/project"
MCP_DIR="$HOME/vrchat-dev/unity-mcp"
PKGS=(vrc_sdk3-worlds vrc_sdk3-avatars udonsharp)

export DEBIAN_FRONTEND=noninteractive

# === Unity Hub のインストール ===
if ! command -v unityhub &>/dev/null; then
  echo "[*] Unity Hub をインストール中…"
  sudo mkdir -p /usr/share/keyrings
  curl -fsSL https://hub.unity3d.com/linux/keys/public \
    | sudo gpg --dearmor -o /usr/share/keyrings/unityhub.gpg
  echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/unityhub.gpg] https://hub.unity3d.com/linux/repos/deb stable main' \
    | sudo tee /etc/apt/sources.list.d/unityhub.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y unityhub
else
  echo "[=] Unity Hub は既にインストール済み"
fi
"""
# === Unity Editor のインストール（VRChat 対応版） ===
echo "[*] 対応版 Unity Editor を検索中…"
INSTALLED=false
for version in "${TARGET_VERSIONS[@]}"; do
  echo "[*] $version を試行…"
  if unityhub -- --headless editors -i | grep -q "^$version"; then
    # changeset を自動取得でインストール
    unityhub -- --headless install \
      --version "$version" \
      --changeset auto \
      --module linux-il2cpp
    INSTALLED=true
    UNITY_VERSION="$version"
    echo "[*] Unity $version のインストール完了"
    break
  fi
done
"""
if ! $INSTALLED; then
  echo "[!] 対応版 Unity Editor がリストに見つかりませんでした。フォールバック処理へ…"
  # 全バージョンから自動取得
  unityhub -- --headless install \
    --version "${TARGET_VERSIONS[0]}" \
    --changeset auto \
    --module linux-il2cpp
  UNITY_VERSION="${TARGET_VERSIONS[0]}"
fi

# === vrc-get のインストール（VRChat SDK 管理ツール） ===
if ! command -v vrc-get &>/dev/null; then
  echo "[*] vrc-get をインストール中…"
  TMP=$(mktemp -d)
  curl -sL "$(curl -sL https://api.github.com/repos/lox9973/vrc-get/releases/latest \
    | grep linux-x64 | grep browser_download_url | cut -d\" -f4)" \
    -o "$TMP/vrc-get.tar.gz"
  tar -xf "$TMP/vrc-get.tar.gz" -C "$TMP"
  sudo install -m755 "$TMP/vrc-get" /usr/local/bin
  rm -rf "$TMP"
else
  echo "[=] vrc-get は既にインストール済み"
fi

# === UnityMCP サーバーのセットアップ ===
if [[ ! -d "$MCP_DIR/UnityMCPforUbuntu22.04" ]]; then
  echo "[*] UnityMCP をクローン中…"
  mkdir -p "$MCP_DIR"
  git clone --depth=1 https://github.com/KAFKA2306/UnityMCPforUbuntu22.04.git \
    "$MCP_DIR/UnityMCPforUbuntu22.04"
else
  echo "[=] UnityMCP は既にクローン済み"
fi

# === Node.js & MCP サーバービルド ===
if ! command -v npm &>/dev/null; then
  echo "[*] Node.js LTS をインストール中…"
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

pushd "$MCP_DIR/UnityMCPforUbuntu22.04/unity-mcp-server" >/dev/null
  echo "[*] npm ci && npm run build"
  npm ci --omit=dev
  npm run build
popd >/dev/null

# === VRChat SDK のインストール ===
mkdir -p "$PROJ_DIR"
for pkg in "${PKGS[@]}"; do
  if ! vrc-get --project "$PROJ_DIR" list | grep -q "$pkg"; then
    echo "[*] vrc-get install $pkg"
    vrc-get --project "$PROJ_DIR" install "$pkg"
  else
    echo "[=] $pkg は既にインストール済み"
  fi
done

# === 完了メッセージ ===
cat <<EOF

========================================
  セットアップ完了 🎉
========================================
Unity Hub      : unityhub
Editor Version : $UNITY_VERSION
プロジェクト   : $PROJ_DIR
MCP サーバー   : $MCP_DIR/UnityMCPforUbuntu22.04/unity-mcp-server

次の手順
------------------------------------------------
1) Unity Hub でサインイン＆ライセンス認証
2) プロジェクトを開く（パス: $PROJ_DIR）
3) 別端末で MCP サーバー起動:
     cd \$MCP_DIR/UnityMCPforUbuntu22.04/unity-mcp-server
     node dist/index.js
4) VRChat ワールド／アバター開発を開始！
EOF
