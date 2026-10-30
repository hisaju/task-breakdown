require "rails_helper"

RSpec.describe "タスク作成機能（S-3）", :js do
  let!(:user) do
    User.create!(
      name: "タスク作成 テスター",
      email_address: "task_creator@example.com",
      password: "password123",
      terms_accepted_at: Time.current
    )
  end

  before do
    # ログインしてホーム画面（/）へ移動
    visit new_session_path
    fill_in "メールアドレス", with: user.email_address
    fill_in "パスワード", with: "password123"
    click_on "ログイン"
  end

  # ------------------------------------------------------------
  # 1: フォーム入力とボタン送信、ショートカットキー送信
  # ------------------------------------------------------------
  describe "タスク作成フロー" do
    it "タイトルを入力してボタンをクリックするとタスクが作成され、詳細画面へ遷移する" do
      find("textarea[aria-label='取り組みたいこと']").fill_in(with: "営業用の見積もりを作成する")
      click_on "タスクを分解する"

      # 詳細モック画面へ遷移し、完了メッセージが表示されること
      expect(page).to have_current_path(task_detail_mock_path)
      expect(page).to have_content(I18n.t("tasks.create.success"))
    end

    it "タイトルを入力してショートカットキー（Ctrl/Cmd + Enter）でタスクを作成できる" do
      textarea = find("textarea[aria-label='取り組みたいこと']")
      textarea.fill_in(with: "ショートカット送信のテスト")

      # キーボードショートカットの送信
      textarea.send_keys([ :control, :enter ])

      # 詳細モック画面へ遷移し、完了メッセージが表示されること
      expect(page).to have_current_path(task_detail_mock_path)
      expect(page).to have_content(I18n.t("tasks.create.success"))
    end
  end

  # ------------------------------------------------------------
  # 2: 入力例チップによる自動入力
  # ------------------------------------------------------------
  describe "入力例チップの連動" do
    it "入力例チップを押すと、テキストエリアにその例文が挿入される" do
      # Task モデルに定義した定数の1件目をクリック
      target_example = Task::EXAMPLES.first
      click_on target_example

      # テキストエリアの値が例文で更新されていること
      expect(find("textarea[aria-label='取り組みたいこと']").value).to eq(target_example)
    end
  end

  # ------------------------------------------------------------
  # 3: 空欄などのバリデーション
  # ------------------------------------------------------------
  describe "バリデーションエラー" do
    it "空欄のまま送信しようとすると送信されない（画面遷移しない）" do
      # 空のままボタンをクリック
      click_on "タスクを分解する"

      # ホーム画面にとどまっていること
      expect(page).to have_current_path(root_path)
    end
  end
end
