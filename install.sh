#!/usr/bin/env bash
set -e

# 任意で変更する推奨 Unity バージョン（VRChat 2025-08 時点）
UNITY_VERSION="2022.3.17f1"

echo "▶ VRChat 開発環境セットアップを開始します…"

# 0. 作業ディレクトリ
mkdir -p ~/VRChatDev && cd ~/VRChatDev

# 1. テンプレート取得（再実行時はスキップ）
[ -d vrchat-world-template ] || \
  git clone --depth=1 https://github.com/vrchat-community/vrchat-world-template.git

# 2. Unity Hub（Linux 公式 apt レポジトリ）
wget -qO - https://hub.unity3d.com/linux/keys/public | sudo apt-key add -
echo 'deb https://hub.unity3d.com/linux/repos/deb stable main' | \
  sudo tee /etc/apt/sources.list.d/unityhub.list > /dev/null
sudo apt update && sudo apt install -y unityhub

# 3. 推奨 Unity Editor を自動インストール（–headless）
unityhub -- --headless install \
  --version "$UNITY_VERSION" \
  --changeset $(unityhub -- --headless editors | grep "$UNITY_VERSION" | awk '{print $2}') \
  --module linux-il2cpp

# 4. 完了メッセージ
cat <<'EOS'

========================================
⚡ セットアップ完了！

$ unityhub &      # Unity Hub GUI 起動
プロジェクト: ~/VRChatDev/vrchat-world-template

※ 初回起動時に VRChat SDK (.unitypackage) もしくは
   VRChat Creator Companion をインポートしてください。
========================================
EOS
