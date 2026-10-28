require "rails_helper"

RSpec.describe "認証機能（本番フロー）", :js do
  # ------------------------------------------------------------
  # 1. 会員登録からホーム画面遷移、サイドバー表示までのフロー
  # ------------------------------------------------------------
  describe "会員登録フロー" do
    it "ユーザーが新規登録を行い、自動ログインしてサイドバーに自身の情報が表示される" do
      # 会員登録画面を開く
      visit new_registration_path

      # フォームへの入力
      fill_in "お名前", with: "新規 太郎"
      fill_in "メールアドレス", with: "new_user@example.com"
      fill_in "パスワード", with: "password123"
      fill_in "パスワード（確認）", with: "password123"
      check "利用規約とプライバシーポリシーに同意する"

      # 登録ボタンをクリック
      click_on "アカウントを作成する"

      # ホーム画面（/）へ遷移すること
      expect(page).to have_current_path(root_path)

      # サイドバー下部に、登録したユーザー名とメールアドレスが表示されていること
      within("aside") do
        expect(page).to have_content("新規 太郎")
        expect(page).to have_content("new_user@example.com")
        # 名前の頭文字アイコンが表示されていること
        expect(page).to have_content("新")
      end
    end
  end

  # ------------------------------------------------------------
  # 2. ログイン、サイドバー確認、ログアウトまでのフロー
  # ------------------------------------------------------------
  describe "ログイン・ログアウトフロー" do
    let!(:user) do
      User.create!(
        name: "ログイン 花子",
        email_address: "hanako@example.com",
        password: "password123",
        terms_accepted_at: Time.current
      )
    end

    it "ログイン後にサイドバー情報が表示され、メニューからログアウトできる" do
      # ログイン画面を開く
      visit new_session_path

      # フォーム入力とログイン実行
      fill_in "メールアドレス", with: user.email_address
      fill_in "パスワード", with: "password123"
      click_on "ログイン"

      # ホーム画面へ遷移すること
      expect(page).to have_current_path(root_path)

      # サイドバー下部にユーザー情報が表示されていること
      within("aside") do
        expect(page).to have_content("ログイン 花子")
        expect(page).to have_content("hanako@example.com")
        expect(page).to have_content("ロ")

        # ユーザーメニュー（…）を開く
        find("button[aria-controls='user-menu']").click
        # メニュー内の「ログアウト」をクリック
        click_on "ログアウト"
      end

      # ログアウト後、ログイン画面へ戻ること
      expect(page).to have_current_path(new_session_path)
    end
  end
end
