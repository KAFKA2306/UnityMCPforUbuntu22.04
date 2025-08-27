# 1コマンドで入る “UnityMCP-Ubuntu22.04” インストーラを用意しました

以下を **そのままコピペ** して実行すれば、GitHub リポジトリの取得から MCP サーバーのビルドまで完了します。Node.js さえ入っていないクリーンな Ubuntu22.04 でも動くようにしました。  

```bash
curl -sL https://raw.githubusercontent.com/KAFKA2306/UnityMCPforUbuntu22.04/main/install.sh | bash
```

***

## install.sh の中身（要点）

```bash
#!/usr/bin/env bash
set -e

# 0. 作業ディレクトリ
mkdir -p ~/UnityMCP && cd ~/UnityMCP

# 1. ソース取得（再実行時はスキップ）
[ -d UnityMCPforUbuntu22.04 ] || \
  git clone --depth=1 https://github.com/KAFKA2306/UnityMCPforUbuntu22.04.git

# 2. Node.js LTS
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# 3. Unity Hub（CLI版で Editor を落とす用途）
wget -qO - https://hub.unity3d.com/linux/keys/public | sudo apt-key add -
echo 'deb https://hub.unity3d.com/linux/repos/deb stable main' \
  | sudo tee /etc/apt/sources.list.d/unityhub.list
sudo apt update && sudo apt install -y unityhub

# 4. MCP サーバー依存／ビルド
cd UnityMCPforUbuntu22.04/unity-mcp-server
npm ci
npm run build              # TypeScript → JS
echo '✓ UnityMCP server built'

# 5. 起動方法メモを表示
cat <<'EOS'

========================================
⚡  セットアップ完了！
$ node dist/index.js           # MCP サーバー起動（stdio）
別ターミナルから JSON-RPC を投げれば即利用できます。
EOS
```

### 使い方メモ

1. `node dist/index.js` で MCP サーバーを立ち上げる。  
2. 好みの JSON-RPC クライアント（自作の `mcp.js` でも OK）から `getVersion` などを呼び出す。  
3. Unity Editor は必要に応じてヘッドレスで自動起動される。
