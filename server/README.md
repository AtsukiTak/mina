## インフラストラクチャ

- Cloud Run
- Cloud Build
- Cloud Registry
- Cloud Scheduler
- Elephant SQL

## Docker Build

まずビルド用のDockerイメージをビルドし、そのイメージでビルドした成果物を取り込む.
Cloud Buildでキャッシュを効かせながらビルドを行うためにこのような構成になっている.

1. `docker build -t musl-builder -f musl-build/Dockerfile`
1. `docker run -v $(pwd)/musl-build:/home/rust/src/musl-build musl-builder`
1. `docker build -t mina-app-server .`
