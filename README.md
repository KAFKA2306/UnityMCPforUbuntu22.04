Linux、特にUbuntuをメインのOSとして使用する開発者にとって、VRChatのワールドやアバター制作環境を整えるのは、これまで少々手間のかかる作業でした。Unity Hubのインストール、特定バージョンのUnity Editorの導入、VRChat SDKやUdonSharpのセットアップなど、複数のステップを正確に実行する必要がありました。[1][2][3]

今回解説するシェルスクリプトは、これら全てのプロセスを単一のコマンドで自動化し、Ubuntu 22.04 LTS上にクリーンで再現性の高いVRChat開発環境を構築します。

#### **この記事で解説するスクリプトの利点**

*   **完全自動**: `curl | bash` のパイプラインで実行するだけで、対話操作なしにセットアップが完了します。
*   **冪等性（べきとうせい）**: 何度実行しても安全です。インストール済みのコンポーネントは検知してスキップするため、環境が壊れる心配がありません。
*   **ベストプラクティス準拠**: `apt-key` のような非推奨コマンドを避け、GPGキーを安全に扱うなど、現代的な手法を採用しています。[4]
*   **ヘッドレス設計**: GUIを必要としないUnity Editorを導入するため、CI/CDパイプラインやサーバーでの自動ビルドにも応用可能です。

***

### **スクリプトの機能概要**

このスクリプトは以下のコンポーネントを自動で導入・設定します。

| コンポーネント | 内容 |
| :--- | :--- |
| **Unity Hub** | 公式リポジトリから最新版を安全にインストールします[5]。 |
| **Unity Editor 2022.3.17f1** | VRChat推奨LTS版を、Linux IL2CPPビルドモジュールと共にヘッドレスで導入します。 |
| **vrc-get** | VRChatパッケージ管理の標準ツール `vrc-get` をインストールします。 |
| **VRChat SDK & UdonSharp** | `vrc-get` を利用して、最新のSDKとUdonSharpをプロジェクトに導入します。 |
| **UnityMCP** | ローカルでの改変テストを効率化する `UnityMCP` サーバーを、Node.js LTSと共にセットアップし、ビルドまで行います。 |
| **プロジェクト雛形** | `~/vrchat-dev/project` に、すぐに開発を始められるUnityプロジェクトを作成します。 |
| **ログ出力** | 実行ログを `~/vrchat-dev/install.log` に保存し、後から確認できるようにします。 |

***

### **スクリプトの構造と技術解説**

それでは、スクリプトの各セクションが何を行っているのかを詳しく見ていきましょう。

#### **1. 初期設定とロギング**

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="$HOME/vrchat-dev"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/install.log") 2>&1

export DEBIAN_FRONTEND=noninteractive
```

*   `set -euo pipefail`: スクリプトの堅牢性を高めるためのおまじないです。コマンドが失敗したら即座に停止し、未定義変数の使用を禁止します。
*   `exec > >(tee ...)`: スクリプト全体の標準出力と標準エラー出力を、コンソールとログファイルの両方にリダイレクトします。これにより、実行状況をリアルタイムで確認しつつ、記録も残せます。
*   `DEBIAN_FRONTEND=noninteractive`: `apt-get` などのパッケージ管理コマンドが、ユーザーに確認を求めるプロンプトで停止しないように設定します。

#### **2. Unity Hub のインストール**

```bash
if ! command -v unityhub &>/dev/null; then
  echo "[*] Installing Unity Hub…"
  sudo mkdir -p /usr/share/keyrings
  curl -fsSL https://hub.unity3d.com/linux/keys/public \
    | sudo gpg --dearmor -o /usr/share/keyrings/unityhub.gpg

  echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/unityhub.gpg] \
https://hub.unity3d.com/linux/repos/deb stable main' \
    | sudo tee /etc/apt/sources.list.d/unityhub.list >/dev/null

  sudo apt-get update
  sudo apt-get install -y unityhub
else
  echo "[=] Unity Hub 既にインストール済み"
fi
```
このブロックは、Unityの公式ドキュメントで推奨されている現代的な手法でリポジトリを追加します。[1]
*   `command -v unityhub &>/dev/null`: `unityhub` コマンドが存在するかを確認し、存在すればこのブロックをスキップします。
*   `gpg --dearmor`: `apt-key add` を使わずに、リポジトリのGPG署名キーをバイナリ形式で `/usr/share/keyrings` ディレクトリに直接保存します。これはUbuntu 22.04以降での推奨プラクティスです。[5][4]
*   `signed-by=...`: `sources.list` ファイル内で、使用するGPGキーを明示的に指定します。

#### **3. Unity Editor (ヘッドレス) のインストール**

```bash
if ! unityhub -- --headless editors -i | grep -q "$UNITY_VERSION"; then
  echo "[*] Installing Unity Editor $UNITY_VERSION…"
  CHANGESET=$(unityhub -- --headless editors -a \
               | awk -v v="$UNITY_VERSION" '$1==v{print $2;exit}')
  # ... (中略) ...
  unityhub -- --headless install \
    --version "$UNITY_VERSION" \
    --changeset "$CHANGESET" \
    --module linux-il2cpp
fi
```
Unity Hubのコマンドラインインターフェース（CLI）を利用して、特定のバージョンのEditorをインストールします。
*   `unityhub -- --headless editors -i`: インストール済みのEditor一覧を取得し、目的のバージョンが既にないか確認します。
*   `unityhub -- --headless editors -a`: 利用可能な全Editorバージョンと、それに紐づく「変更セットID（Changeset ID）」を取得します。
*   `awk ...`: `awk`コマンドを使い、目的のバージョン (`$UNITY_VERSION`) に対応するChangeset IDだけを抽出します。
*   `unityhub -- --headless install`: 抽出したバージョンとChangeset IDを使い、目的のEditor本体と、VRChatコンテンツのビルドに必要な `linux-il2cpp` モジュールをインストールします。

#### **4. vrc-get と UnityMCP のセットアップ**

スクリプトは続けて、VRChat開発に不可欠なコミュニティ製ツールを導入します。
*   **vrc-get**: GitHubのリリースAPIを叩いて最新版のURLを取得し、`/usr/local/bin` に配置します。これにより、どのディレクトリからでも `vrc-get` コマンドが使えるようになります。
*   **UnityMCP**: 指定されたGitHubリポジトリをクローンし、サーバーの実行に必要なNode.jsを `nodesource` リポジトリから導入。最後に `npm ci` と `npm run build` を実行して、サーバーアプリケーションをビルドします。依存関係のインストールからビルドまでを自動化しているのがポイントです。

#### **5. プロジェクトの作成とパッケージ導入**

```bash
mkdir -p "$PROJ_DIR"
for pkg in "${PKGS[@]}"; do
  if ! vrc-get --project "$PROJ_DIR" list | grep -q "$pkg"; then
    echo "[*] vrc-get install $pkg"
    vrc-get --project "$PROJ_DIR" install "$pkg"
  fi
done
```
最後の仕上げとして、開発の拠点となるUnityプロジェクトを作成します。
*   `mkdir -p "$PROJ_DIR"`: プロジェクト用のディレクトリを作成します。
*   `for pkg in "${PKGS[@]}"`: `PKGS`配列に定義されたパッケージ（`vrc_sdk3-worlds`, `vrc_sdk3-avatars`, `udonsharp`）をループ処理します。
*   `vrc-get --project "$PROJ_DIR" list`: プロジェクトにインストール済みのパッケージを一覧表示させ、`grep`で目的のパッケージが既にないか確認します。
*   `vrc-get install "$pkg"`: パッケージがなければ、`vrc-get` を使ってプロジェクトにインストールします。

### **結論**

このシェルスクリプトは、単にコマンドを並べただけのものではありません。冪等性の確保、エラーハンドリング、最新のパッケージ管理手法の採用など、堅牢な自動化を実現するための工夫が随所に凝らされています。

LinuxユーザーがVRChatのコンテンツ制作を始める際の障壁を劇的に下げ、より多くのクリエイターが自分の好きな環境で創造性を発揮できるようになる、優れたソリューションと言えるでしょう。

[1](https://docs.unity3d.com/hub/manual/InstallHub.html)
[2](https://sandman73773941.hatenablog.com/entry/2020/07/13/223102)
[3](https://chromitz.com/20191231-unity3d-vrchat-sdk-install-on-ubuntu-by-unityhub/)
[4](https://discussions.unity.com/t/how-to-install-unity-hub-3-4-1-in-ubuntu-22-04-lts/888523)
[5](https://ultahost.com/knowledge-base/install-unity-on-ubuntu/)
[6](https://github.com/KAFKA2306/UnityMCPforUbuntu22.04/blob/main/install.sh)
[7](https://www.youtube.com/watch?v=YHn8-UlZSLM)
[8](https://discussions.unity.com/t/unity-accelerator-ubuntu-20-04-server-headless-install/824887)
[9](https://gist.github.com/bladeSk/0fd443f9721f222551e0ed2611681c1a)
[10](https://discussions.unity.com/t/running-unity-on-ubuntu-22-04/882161)
[11](https://www.youtube.com/watch?v=JJDb2aeXlhA)
[12](https://www.youtube.com/watch?v=bSvOjm9D4-I)
[13](https://www.youtube.com/watch?v=VaWzh8pzGeI)
