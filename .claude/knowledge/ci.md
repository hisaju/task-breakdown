# CI の知見

- GitHub Actions（`.github/workflows/ci.yml`）: brakeman / bundler-audit / importmap audit / rubocop / rspec
- rspec ジョブは PostgreSQL サービスコンテナを使う。DB 接続は `DB_HOST` 等の環境変数（`config/database.yml`）
