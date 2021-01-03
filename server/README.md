## インフラストラクチャ

- Cloud Run
- Cloud Build
- Cloud Registry
- Cloud Scheduler
- Elephant SQL

## Docker Build

Cyclic Docker Buildという手法。
ビルドを2段階に分け、1段階目でビルド成果物とキャッシュアーカイブを保持するDockerイメージを生成し、
2段回目でビルド成果物を取り込んだDockerイメージを生成する。
そして1段階目のDockerイメージを次回のビルドのソースにすることで、キャッシュを有効にする。
