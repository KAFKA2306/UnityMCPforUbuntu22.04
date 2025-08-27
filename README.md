# Node.js のみで構成する **超ミニマル Unity MCP スタック**（Ubuntu 22.04）

**Node.js だけ**で Unity MCP を動かす最小ルートを示します。作業はすべてターミナルで完結し、WSL2 でも同手順で機能します。

***

## 1. 前提ソフト

```bash
# Node.js LTS
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs git
```

***

## 2. Unity Hub & エディター（CLI 版）

Unity 本体は必要なので、公式 CLI ツールで取得します。GUI Hub を入れずに済むため軽量です。

```bash
# unity-downloader-cli を取得
npm i -g unity-downloader-cli

# 例: 2022.3 LTS の Linux プレイヤー付き最小パッケージ
unity-downloader-cli -u 2022.3.15f1 \
  -c Editor Linux IL2CPP \
  -d ~/Unity
```

インストール後、`~/Unity/Editor/Unity` がヘッドレス実行に使えます。

***

## 3. Unity MCP サーバー（Node.js 版のみ）

```bash
# ソース取得
git clone https://github.com/unity-mcp/unity-mcp-server.git
cd unity-mcp-server

# 依存を一括で
npm ci    # lockfile あり、再現性◎

# ビルド
npm run build        # TypeScript → JS（1回だけ）
```

### 3-1 サーバー起動

```bash
node dist/index.js          # JSON-RPC over stdio
```

デフォルトは stdin/stdout で待ち受けるため、後述の CLI クライアントと直接パイプできます。

***

## 4. シェル 1 ファイルの最小 CLI クライアント

`mcp.js` — 依存ゼロ、node だけで動く 60 行弱のスクリプトです。

```javascript
#!/usr/bin/env node
/* eslint-disable no-console */
const {spawn} = require('node:child_process');
const id = () => Math.random().toString(36).slice(2);

if (process.argv.length < 3) {
  console.error('usage: mcp.js <method> [jsonParams]');
  process.exit(1);
}
const [,, method, params = '{}'] = process.argv;

const srv = spawn('node', ['dist/index.js'], {cwd: 'unity-mcp-server'});
srv.stdin.setDefaultEncoding('utf8');

srv.stdout.on('data', d => {
  const res = JSON.parse(d.toString());
  console.log('→', JSON.stringify(res, null, 2));
  process.exit(0);
});

const req = {jsonrpc: '2.0', id: id(), method, params: JSON.parse(params)};
srv.stdin.write(JSON.stringify(req) + '\n');
```

```bash
chmod +x mcp.js
```

例: バージョン取得

```bash
./mcp.js getVersion
```

***

## 5. Unity プロジェクトと連携

1. 空の 3D プロジェクトを用意（任意のフォルダー）。
2. 上記サーバーを起動したまま、プロジェクト側で下記スクリプトを実行すると AI からのコマンドを受信できます。

```bash
# 例: シーン一覧を取得
./mcp.js getSceneList '{"projectRoot":"/path/to/UnityProject"}'
```

サーバーが Unity Editor を必要に応じてヘッドレス起動し、JSON-RPC 経由で結果を返します。[1][2][3]

***

## 6. この構成の特徴

- **完全 Node.js**：追加ランタイムなし。CI/CD も npm スクリプトだけで回せる。
- **ファイル 2 つ**：`unity-mcp-server` と `mcp.js` だけで完結。
- **0 GUI**：Electron 製の Claude Desktop も Unity Hub GUI も不要。
- **再現性**：`npm ci` と lockfile で開発マシン間の差異を最小化。
- **ヘッドレス対応**：Unity Editor をバッチモードで呼び出すため、GPU がないクラウドサーバーでも実行可能。

***

これで **Node.js のみ**による Unity MCP の超軽量スタックが完成します。

[1](https://www.youtube.com/watch?v=V7VP_Jkc8b8)
[2](https://mcp.aibase.com/server/1916355692431646722)
[3](https://github.com/pazuzu1w/ubuntu_mcp_server)
