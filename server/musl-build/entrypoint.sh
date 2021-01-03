#!/bin/bash

# ビルドの前後でキャッシュを展開、更新するスクリプト
# ビルド成果物とキャッシュアーカイブはmusl-buildディレクトリにまとめる

# Dockerコンテナの/home/rust/srcから呼ばれることを想定
if ["$(pwd)" -ne "/home/rust/src"]; then
  echo "invalid context"
  exit 1
fi

# キャッシュアーカイブを展開
# アーカイブファイルがなくても終了しない
echo "extracing cache archive..."
tar xfp musl-build/cache.tar.gz -C /

# ビルド
echo "building..."
cargo build --release -p mina-app
cp target/x86_64-unknown-linux-musl/release/mina-app musl-build/mina-app

# キャッシュアーカイブを作成（更新）
# 展開時にルートディレクトリに対して一括で展開できるように
# 絶対パスで指定している
echo "updating cache archive..."
tar cfz musl-build/cache.tar.gz /home/rust/src/target /home/rust/.cargo/registry/index /home/rust/.cargo/registry/cache
