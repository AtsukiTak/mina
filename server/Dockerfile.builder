# mina-backend-builderには前回のキャッシュが含まれている
FROM gcr.io/mina-295407/mina-backend-builder as prev

# 使用するRustのバージョンを変えられるようにする
FROM ekidd/rust-musl-builder:1.47.0 as current
WORKDIR /home/rust/src
# 前回のキャッシュを引っ張ってくる
COPY --from=prev /home/builder/cache.tar.gz .
# ソースコード
COPY . .
# キャッシュを展開
RUN tar xfp cache.tar.gz -C /
# ビルド
RUN cargo build --release
# キャッシュの更新
RUN rm cache.tar.gz && tar cfz cache.tar.gz /home/rust/src/target /home/rust/.cargo/registry/index /home/rust/.cargo/registry/cache

# ビルド成果物とキャッシュを保持するコンテナイメージ
FROM alpine:latest
WORKDIR /home/builder
# 次回使用するキャッシュ
COPY --from=current /home/rust/src/cache.tar.gz ./cache.tar.gz
# ビルド成果物
COPY --from=current /home/rust/src/target/x86_64-unknown-linux-musl/release/mina-app ./mina-app
ENTRYPOINT ["echo", "hoge"]
