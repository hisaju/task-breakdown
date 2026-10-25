# リポジトリ・環境の知見

- コマンドはすべて `docker compose run --rm web ...` で実行する。ホストの Ruby で `bin/rails` を叩くと DB に繋がらない
- Tailwind の watch はコンテナ内で `poll` モード（`tailwindcss:watch[always,poll]`）。macOS のボリューム越しではファイル変更イベントが届かないため
- CSS が反映されないときは `docker compose run --rm css bin/rails tailwindcss:build` で手動ビルド
- `@theme` に追加した色は `bg-<name>` 等で使える。トークン一覧は `app/assets/tailwind/application.css`
- 画面モック段階: ルーティングは `MocksController`（`/` `/tasks` `/tasks/sample` `/signup` `/login`）。本実装時は `docs/screens.md` の「URL（実装予定）」に置き換え、モックは削除する
- SimpleCov の閾値は `MIN_COVERAGE`（既定 0。ロジック実装後は 80 に戻す）
