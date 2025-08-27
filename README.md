# VRChatDevforUbuntu22.04

Ubuntu 22.04 LTS で **VRChat ワールド／アバター開発環境**を最速構築するセットアップスクリプトです。  
Unity Hub（Linux 版）と、VRChat 推奨 Unity エディタ（2022.3 LTS 系）を CLI で自動導入し、  
公式テンプレートプロジェクトをクローンします。

## セットアップ手順

```
curl -sL https://raw.githubusercontent.com/<YOUR-USER>/VRChatDevforUbuntu22.04/main/install.sh | bash
```

– 実行が終わると `~/VRChatDev/vrchat-world-template` が作成され、  
  Unity Hub 内に推奨バージョンの Unity Editor が表示されます。

## 開発を始める

1. Unity Hub を起動  
   ```
   unityhub &
   ```
2. 「作業を開始」→「既存プロジェクトを開く」で  
   `~/VRChatDev/vrchat-world-template` を選択。
3. プロジェクトが開いたら **VRChat SDK**（Creator Companion もしくは .unitypackage）をインポートし、  
   ワールド／アバターの制作を開始してください。

## よくある質問

- **Unity 版数を変えたい**  
  `install.sh` の `UNITY_VERSION` を編集して再実行すると別バージョンを追加できます。  
- **アンインストール**  
  ```
  sudo apt remove unityhub
  sudo rm -rf ~/VRChatDev
  sudo rm /etc/apt/sources.list.d/unityhub.list
  sudo apt-key del "$(sudo apt-key list | grep -B1 hub.unity3d | head -n1 | awk '{print $2}')"
  ```
```

***

## install.sh（新）

```bash
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
```
