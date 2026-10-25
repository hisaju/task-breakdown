---
name: run
description: Tasklet アプリを Docker Compose で起動し、ブラウザ（Playwright）で画面を確認する手順。UI の受入確認や「起動して」「画面を見せて」の依頼で使う。
---

# アプリの起動と画面確認

## 起動
```bash
docker compose up -d
docker compose run --rm web bin/rails db:prepare   # 初回・マイグレーション追加時
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/up   # 200 なら起動完了
```

## 画面（モック段階）
| URL | 画面 |
|---|---|
| http://localhost:3000/ | タスクを作る |
| http://localhost:3000/tasks | マイタスク（親タスク一覧） |
| http://localhost:3000/tasks/sample | タスク詳細（分解結果） |
| http://localhost:3000/signup | 会員登録 |
| http://localhost:3000/login | ログイン |

## 画面確認
- `playwright-check` スキルの手順で、上記 URL を 1440×900 でスクリーンショットし、`docs/screens.md` の要素と照合する
- コンソールエラーが無いことも確認する

## うまくいかないとき
| 症状 | 対処 |
|---|---|
| CSS が古い・色が付かない | `docker compose run --rm css bin/rails tailwindcss:build` |
| `A server is already running` | `docker compose restart web` |
| DB に接続できない | `docker compose ps` で db が healthy か確認 |

## 停止
```bash
docker compose stop
```
