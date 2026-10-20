#!/bin/sh
# 指定タグの pop-launcher にパッチを当ててビルドし、利用者側のプラグインとして配置する
# 使い方: ./build-and-install.sh [タグ]   (省略時は 1.2.7)
set -eu

tag="${1:-1.2.7}"
repo_dir="$(cd "$(dirname "$0")" && pwd)"
patch_file="$repo_dir/patches/0001-cosmic-toplevel-reload-and-hide-untitled.patch"
build_dir="${TMPDIR:-/tmp}/pop-launcher-build-$tag"
dest="$HOME/.local/share/pop-launcher/plugins/cosmic_toplevel"

if [ -e "$build_dir" ]; then
    echo "作業ディレクトリが既に存在します: $build_dir" >&2
    exit 1
fi

git clone --depth 1 --branch "$tag" https://github.com/pop-os/launcher.git "$build_dir"
cd "$build_dir"
git apply --check "$patch_file"
git apply "$patch_file"
cargo build --release -p pop-launcher-bin

mkdir -p "$dest"
install -m0755 target/release/pop-launcher-bin "$dest/cosmic-toplevel"
install -m0644 /usr/lib/pop-launcher/plugins/cosmic_toplevel/plugin.ron "$dest/plugin.ron"
sha256sum /usr/bin/pop-launcher > "$repo_dir/pop-launcher-bin.sha256"

echo "配置しました: $dest"
echo "反映にはログインし直してください。"
