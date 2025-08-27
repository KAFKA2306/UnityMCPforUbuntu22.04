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
