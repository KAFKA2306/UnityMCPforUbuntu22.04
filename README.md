`curl | bash` のワンライナーを叩くだけで、従来 **Windows 前提**とされていた VRChat 制作環境を **Ubuntu 22.04** に非対話で整えられます。  

```bash
curl -sL https://raw.githubusercontent.com/KAFKA2306/UnityMCPforUbuntu22.04/main/install.sh | bash
```

-  **Unity Hub & Unity Editor 2022.3 LTS（ヘッドレス）** を自動インストール  
-  **vrc-get** で **SDK3 Worlds / Avatars + UdonSharp** を即投入  
-  **UnityMCP サーバー** を Node.js LTS 込みでビルド配置  

Unityhubとunityが連携しない助けて
