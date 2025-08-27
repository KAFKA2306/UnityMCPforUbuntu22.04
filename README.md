Ubuntu 22.04でVRChat開発環境を一気に整えるシェルスクリプトです。

-  **Unity Hub（APT repo）**と**Unity Editor 2022.3 LTS（ヘッドレス）**を自動導入  
-  **vrc-get**で**SDK3 Worlds／Avatars**と**UdonSharp**を即投入  
-  **UnityMCPサーバー**をNode.js LTS込みでビルド配置  
-  完全非対話・再実行安全・ログは `~/vrchat-dev/install.log`  
-  実行は  
```bash
curl -sL https://raw.githubusercontent.com/KAFKA2306/UnityMCPforUbuntu22.04/blob/main/install.sh | bash
```
Windows依存が指摘されてきたVRChat開発をUbuntuでも簡単に始められます
