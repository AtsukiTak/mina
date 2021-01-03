FROM ekidd/rust-musl-builder:1.47.0
WORKDIR /home/rust/src
COPY . .
# ビルドの前後でキャッシュを展開、更新するスクリプト
ENTRYPOINT ["./musl-build/entrypoint.sh"]
