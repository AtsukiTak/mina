## インフラストラクチャ一覧

- [Cloud Run](#cloud-run)
- [Cloud Build](#cloud-build)
- Cloud Registry
- Cloud Scheduler
- Elephant SQL

## Cloud Run

サービス名 : `mina-backend`

### trafficが自動で切り替わらない時

デフォルトでは新しいリビジョンをpushしたとき、そのリビジョンにトラフィックが移行される。
しかしWebコンソールなどから過去のリビジョンにトラフィックを切り替えたりすると、次回から新規リビジョンへのトラフィック切り替えが無効になってしまう。
考えればこの仕様は安全面から当然と言える。
新規リビジョンへの自動トラフィック移行を再び有効にするためには、以下のコマンドを実行する

`gcloud run services update-traffic mina-backend --to-latest --platform managed --region asia-northeast1`

## Cloud Build

### Docker build

Cyclic Docker Buildという手法。
ビルドを2段階に分け、1段階目でビルド成果物とキャッシュアーカイブを保持するDockerイメージを生成し、
2段回目でビルド成果物を取り込んだDockerイメージを生成する。
そして1段階目のDockerイメージを次回のビルドのソースにすることで、キャッシュを有効にする。
