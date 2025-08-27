#!/usr/bin/env bash
set -euo pipefail

# versions / paths
UNITY_VERS="2022.3.17f1"
PROJ_DIR="$HOME/vrchat-dev/project"
PKGS=(vrc_sdk3-worlds vrc_sdk3-avatars udonsharp)
MCP_DIR="$HOME/vrchat-dev/unity-mcp"

# hub
command -v unityhub >/dev/null || {
  wget -qO- https://hub.unity3d.com/linux/keys/public | sudo apt-key add -
  echo 'deb https://hub.unity3d.com/linux/repos/deb stable main' | sudo tee /etc/apt/sources.list.d/unityhub.list >/dev/null
  sudo apt update && sudo apt install -y unityhub
}

# unity editor
unityhub -- --headless editors | grep -q "$UNITY_VERS" || {
  cs=$(unityhub -- --headless editors | awk -v v="$UNITY_VERS" '$1==v{print $2;exit}')
  unityhub -- --headless install --version "$UNITY_VERS" --changeset "$cs" --module linux-il2cpp
}

# vrc-get
command -v vrc-get >/dev/null || {
  tmp=$(mktemp -d)
  curl -sL "$(curl -sL https://api.github.com/repos/lox9973/vrc-get/releases/latest | grep linux-x64 | grep browser_download_url | cut -d'"' -f4)" -o "$tmp/vrc-get.tar.gz"
  tar -xzf "$tmp/vrc-get.tar.gz" -C "$tmp"
  sudo install -m755 "$tmp/vrc-get" /usr/local/bin
  rm -r "$tmp"
}

# unity-mcp
mkdir -p "$MCP_DIR" && cd "$MCP_DIR"
[ -d UnityMCPforUbuntu22.04 ] || git clone --depth=1 https://github.com/KAFKA2306/UnityMCPforUbuntu22.04.git
cd UnityMCPforUbuntu22.04/unity-mcp-server
command -v npm >/dev/null || { curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -; sudo apt-get install -y nodejs; }
npm ci && npm run build

# project + packages
mkdir -p "$PROJ_DIR"
for p in "${PKGS[@]}"; do
  vrc-get --project "$PROJ_DIR" install "$p"
done

echo "ready – project: $PROJ_DIR   mcp: $MCP_DIR/UnityMCPforUbuntu22.04/unity-mcp-server"
