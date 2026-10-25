# Tasklet — AI タスク分解アプリ

「見積もり作成」「起案書作成」のような大まかなタスクを入力すると、AI が実行できる手順（サブタスク）に分解し、期限から逆算して進められるようにするアプリです。

> 現在は**画面モック**の段階です。画面は固定データで表示しており、保存や AI 分解は行いません。

## 必要なもの
- Docker / Docker Compose

## セットアップ

```bash
docker compose build
docker compose run --rm web bin/rails db:prepare
docker compose up -d
```

http://localhost:3000 を開きます。

| 画面 | URL |
|---|---|
| タスクを作る | http://localhost:3000/ |
| マイタスク | http://localhost:3000/tasks |
| タスク詳細 | http://localhost:3000/tasks/sample |
| 会員登録 | http://localhost:3000/signup |
| ログイン | http://localhost:3000/login |

停止は `docker compose stop` です。

## 開発で使うコマンド

| 用途 | コマンド |
|---|---|
| テスト | `docker compose run --rm web bundle exec rspec` |
| Lint | `docker compose run --rm web bin/rubocop` |
| セキュリティ診断 | `docker compose run --rm web bin/brakeman` |
| CSS の再ビルド | `docker compose run --rm css bin/rails tailwindcss:build` |

## ドキュメント
仕様・開発ルールは [docs/](docs/README.md) を参照してください。
