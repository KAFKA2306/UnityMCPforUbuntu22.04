# claude-code VRChat Headless Dev Environment for Ubuntu 22.04

**Unity Hub / Unity Editor（ヘッドレス） / vrc-get / UnityMCP** を  
`curl | bash` 一発で構築するスクリプトと最小プロジェクトを提供します。

---

## 特長
- **Unity Hub**（公式 APT リポジトリ版）を自動導入  
- **Unity Editor 2022.3 LTS** を *headless* でインストール  
- **vrc-get** により  
  - **SDK3 Worlds / SDK3 Avatars**  
  - **UdonSharp**  
  を即時投入  
- **UnityMCP サーバー** と **Node.js LTS** をビルド済みで配置  
- すべて非対話式、再実行しても重複インストールなし

---

## クイックスタート

```
# スクリプトを取得して実行
curl -sL https://raw.githubusercontent.com/<YOUR-USER>/claude-code-vrchat-dev/main/install.sh | bash
```

---

## 使用方法

1. **Unity Hub** を起動  
   ```
   unityhub &
   ```
2. プロジェクト `~/vrchat-dev/project` を Hub で開く  
3. **UnityMCP サーバー** を別端末で起動（必要に応じて）  
   ```
   cd ~/vrchat-dev/unity-mcp/UnityMCPforUbuntu22.04/unity-mcp-server
   node dist/index.js
   ```
4. VRChat ワールド／アバター開発を開始

---
