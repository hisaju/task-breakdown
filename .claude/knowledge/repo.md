# リポジトリ・環境の知見

- コマンドはすべて `docker compose run --rm web ...` で実行する。ホストの Ruby で `bin/rails` を叩くと DB に繋がらない
- Tailwind の watch はコンテナ内で `poll` モード（`tailwindcss:watch[always,poll]`）。macOS のボリューム越しではファイル変更イベントが届かないため
- CSS が反映されないときは `docker compose run --rm css bin/rails tailwindcss:build` で手動ビルド
- 画面モック段階: ルーティングは `MocksController`（`/` `/tasks` `/tasks/sample` `/signup` `/login`）。本実装時は `docs/screens.md` の「URL（実装予定）」に置き換え、モックは削除する
- SimpleCov の閾値は `MIN_COVERAGE`（既定 0。ロジック実装後は 80 に戻す）

## デザイントークン（`app/assets/tailwind/application.css` の `@theme`）
- ビューに `#xxxxxx` / `rgba(` / `text-[9px]` を書かない（`grep -rnE '#[0-9a-fA-F]{6}|rgba\(|text-\[9px\]' app/views` が 0 件であること）。`@theme` に足した値は `bg-<name>` `text-<name>` `shadow-<name>` 等で使える
- 色: `ink` `muted` `subtle` `canvas` `line` `line-strong`（完了チェックの丸枠）`line-dashed`（「タスクを追加」の破線）`brand` `brand-hover` `brand-soft` `brand-dot` `accent` `accent-soft` `danger`（失敗・削除の文字）`danger-dot`（失敗の点）`danger-soft`（エラー背景。未使用）`avatar`
- 影: `shadow-card`（カードのホバー）`shadow-float`（フォームカード）。文字: `text-2xs`（10px。最小サイズ）
- Tailwind v4 は使われたトークンだけ CSS に出す（未使用の `danger-soft` はビルド結果に出ない）。ビルドは圧縮され `rgba(32,36,33,0.18)` → `#2024212e`、`0.213` → `.213` になる
- `spec/assets/design_tokens_spec.rb` がビルド後の CSS（`app/assets/builds/tailwind.css`）を読んで値を検査する。事前に `docker compose run --rm css bin/rails tailwindcss:build` が必要（css コンテナが watch 中なら最新）
- フォーカス表示はビューにクラスを書かず、`@layer base` の `:where(a[href], button, [role=tab], [role=menuitem]):focus-visible` で `ring-2 ring-brand-dot` を一括適用している（`brand-soft` は白地でコントラスト約 1.1:1 で見えないため使わない。入力欄の `focus:ring-brand-soft` は枠線 `border-brand` と併用なので別扱い）
- `<head>` は `layouts/_head.html.erb` に集約（両レイアウトが render）。画面タイトルは `content_for :title`、追加タグは `content_for :head`

## サンプルデータ（`MocksController`）
- 定数ではなく private メソッド（`sample_subtasks` / `sample_parent_tasks` / `date_tabs` / `new_subtask`）。`helper_method` でビューから呼ぶ。リクエストごとに `Time.current` 基準で評価されるので「今日」「明日」が常に成り立つ
- 期限は相対日時（今日 12:00・17:00・18:00／明日 12:00／7 日後 17:00／nil）。サブタスクの期限は親の期限を超えない（「社内提案資料を作成する」は 7 日後 17:00）
- サブタスク 6 件のうち 1 件目が完了済み（`done: true`）、6 件目が期限なし。親タスクに全完了（「経費精算の締め確認」3/3）を含む
- S-5「社内提案資料を作成する」の `done/total` は `sample_subtasks` から導出。他の行の進捗は固定値
- S-5 の親行 `<li>` は `data-done`（`total > 0` かつ `done == total` で "true"）と `data-due-key` を持つ。現状 "true" は「経費精算の締め確認」だけ
- 期限の表示はすべて `DueDateHelper`（`due_label` / `due_key` / `due_time_tag`）を通す。期限は `<time datetime>` で出力され、spec はこれを拾って書式を検査する。カードとタブには `data-due-key`（today / tomorrow / YYYY-MM-DD / none）が付く
- 日付に依存する spec は `travel_to` で固定する（`ActiveSupport::Testing::TimeHelpers` は `rails_helper` で全 spec に include 済み）

## system spec（`spec/system/`）
- JS を動かす spec は `:js` を付ける（`type: :system` は配置から推論）。ドライバは cuprite（`spec/support/capybara.rb` の `:cuprite_ja`、1280x900・ja-JP）。`:js` なしは rack_test
- ローカル: `docker compose run --rm web bundle exec rspec spec/system`。Chromium は `Dockerfile.dev` に入っており `BROWSER_PATH=/usr/bin/chromium`。イメージが古ければ `docker compose build web`
- 画面を見ながらデバッグしたいときはホストで動かせないので、`page.save_screenshot("x.png")` で画像を残して確認する。相対パスは `Capybara.save_path`（`tmp/capybara/`）基準になる（`"tmp/screenshots/x.png"` と書くと `tmp/capybara/tmp/screenshots/` に出る）
- cuprite の `click` / `hover` は対象を画面中央付近へスクロールしてから操作する。sticky なサイドバー下部の要素をクリックすると `window.scrollY` が変わり、スクリーンショットの見た目がずれる（アプリの挙動ではない）。見た目を撮るときは `execute_script("...click()")` で押す
- 失敗時のスクリーンショットは `tmp/screenshots/` に保存される

## 作業ディレクトリの共有
- 複数のエージェント（developer / tester 等）が同じ作業ディレクトリを使う。tester が比較のために `git switch main` や特定コミットを checkout すると、developer 側が detached HEAD になり push が漏れる。別リビジョンとの比較は `git worktree add ../tb-main origin/main` など別ディレクトリで行う（#12, 2026-10-25）

## モックの共通部品と規約
- **no-op ボタン**: 押しても何も起きない「見た目だけ」のボタンは `type="button" data-mock="noop"` を必ず付ける。削除・再分解などの破壊的な項目も no-op で、確認ダイアログは出さない。`docs/screens.md` の要素表では「（見た目のみ）」と注記する
- **非表示**: 完了フィルタ・日付タブで隠す要素は `data-hidden-by-done` / `data-hidden-by-tab` 属性で表し、`application.css` のレイヤー外ルール（`display: none`）で消す。`hidden` 属性やクラスの付け外しで隠さない（メニュー本体と空状態の表示切替だけは `hidden` 属性）
- `shared/_decomposition_status`（`status: :decomposing | :done | :failed`。ルートに `data-decomposition-status`）: S-4 見出し上・S-5 カードで同じマークアップ。未知の値は例外
- `shared/_menu`（`id:` `items: [{ label:, href:, danger: }]` `placement: :down | :up` `label:`）＋ `menu_controller.js`: `href` 付き項目は `<a role="menuitem">`、無い項目は no-op ボタン。開閉状態はトリガーの `aria-expanded` とメニューの `hidden`。外側クリック・Esc（トリガーへフォーカスを戻す）で閉じ、↑↓/Home/End で項目移動。`id` は画面内で一意にする（サイドバーは `user-menu`）
- `mocks/_content_header`（S-4・S-5 のヘッダー。左はブロックで渡す）＋ `completed_filter_controller.js`: 両画面とも `<header>` と本文を `data-controller="completed-filter"` のラッパーで包む。状態はトグルの `aria-pressed` だけ。ラッパー内の `[data-done]` を対象に、`data-done="true"` へ `data-hidden-by-done` を付け外しする。初期描画でもサーバ側で `data-hidden-by-done` を付けておく（JS 前のちらつき防止・request spec で検査できる）。`MutationObserver` で `data-done` / `data-hidden-by-tab` の変化と要素の追加に追随するので、完了チェックや日付タブ側から通知は不要。表示対象が 0 件になったら `data-completed-filter-target="empty"` の要素の `hidden` を外す（`[data-done]` が 1 件も無い画面では出さない）
- `shared/_empty_state`（`icon:` `title:` `body:` `action: { label:, href: }` `data:` `hidden:`）、`shared/_task_progress`（`done:` `total:`。`total` 0 は「—」。ルートに `data-task-progress`）
- 部品の単体検査は `spec/views/shared/`（view spec）
