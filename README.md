# pop-launcher cosmic_toplevel ローカル修正

COSMIC Launcher のランチャー表示とウィンドウスイッチャー（Alt+Tab / Super+Tab）に出るウィンドウ一覧の不具合を、
pop-launcher の `cosmic_toplevel` プラグインだけ差し替えて修正する。2026-10-20 適用。

## 症状と原因

- **セッション中に入れたアプリのアイコンが出ない**（例: Okular）
  プラグインは常駐型（`long_lived: true`）で、`.desktop` を起動時に1回しか読まない。
  セッション開始後にインストールしたアプリは照合できず、既定アイコンになる。
- **Clip Studio Paint が大量に並ぶ**
  Wine（XWayland）が 1x1 の無題ダイアログ（`_NET_WM_STATE_SKIP_TASKBAR` 付き）を5個公開している。
  cosmic-comp は SKIP_TASKBAR を見ずに全ウィンドウを公開し、プラグインも全件を並べる。

上流（pop-os/launcher master 3f35b7f、cosmic-comp master 742b800）では未修正、既存 Issue なし（2026-10-20 時点）。

## 修正内容

`patches/0001-cosmic-toplevel-reload-and-hide-untitled.patch`（上流タグ 1.2.7 に対する差分）

- 問い合わせ時に未解決の app_id がある場合だけ `.desktop` を再走査する。最短間隔は30秒。
  解決済みのアプリだけなら再走査しない。
- タイトルが空のウィンドウは、同じ app_id にタイトル付きのウィンドウがある場合だけ隠す。
  プラグインには SKIP_TASKBAR が届かないための近似。単独の無題ウィンドウは表示する。

## 配置

pop-launcher はプラグインを `~/.local/share/pop-launcher/plugins` → `/etc/pop-launcher/plugins` →
`/usr/lib/pop-launcher/plugins` の順に探し、同名プラグイン（`plugin.ron` の `name`）は最初のものだけを使う。

- `~/.local/share/pop-launcher/plugins/cosmic_toplevel/cosmic-toplevel`: 修正版の pop-launcher-bin（名前で呼び分け）
- `~/.local/share/pop-launcher/plugins/cosmic_toplevel/plugin.ron`: 配布版のコピー

`/usr` 以下のファイルは変更しない。反映にはログインし直しが必要。

## ビルド

`./build-and-install.sh [タグ]` で以下をまとめて実行する（タグ省略時は 1.2.7）。
パッチが当たらない場合は `git apply --check` の段階で止まる。手動で行う場合:

```sh
git clone --depth 1 --branch 1.2.7 https://github.com/pop-os/launcher.git /tmp/pop-launcher-build
cd /tmp/pop-launcher-build
git apply ~/project/pop-launcher-local-patch/patches/0001-cosmic-toplevel-reload-and-hide-untitled.patch
cargo build --release -p pop-launcher-bin
install -m0755 target/release/pop-launcher-bin ~/.local/share/pop-launcher/plugins/cosmic_toplevel/cosmic-toplevel
install -m0644 /usr/lib/pop-launcher/plugins/cosmic_toplevel/plugin.ron ~/.local/share/pop-launcher/plugins/cosmic_toplevel/
```

## 検証（2026-10-20）

- 稼働中のウィンドウに対する空検索で、CSP が6件から1件（タイトル付きの本体）になった。他のアプリは変化なし。
- 空の XDG ディレクトリで起動し、後から `org.kde.okular.desktop` を追加すると、
  30秒経過前は既定アイコン、経過後の問い合わせで `okular` に解決された。

## pop-launcher 更新時

`pop-launcher-bin.sha256` は適用時の `/usr/bin/pop-launcher` のハッシュ。
パッケージが更新されたら（`sha256sum -c pop-launcher-bin.sha256` が失敗したら）、
新しいタグで `./build-and-install.sh <新タグ>` を実行する。パッチが当たらなければ移植してパッチを更新する。放置すると、修正版の古いプラグインと新しい本体が組み合わさる。
2025-10 の 1.2.7 以降リリースはなく、更新は稀。

## 元に戻す

```sh
rm -r ~/.local/share/pop-launcher/plugins/cosmic_toplevel
```

その後ログインし直す。
