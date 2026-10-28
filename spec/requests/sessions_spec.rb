require "rails_helper"

RSpec.describe "セッション管理（ログイン・ログアウト）" do
  # テスト全体で使うユーザーデータ
  let!(:user) do
    User.create!(
      name: "テストユーザー",
      email_address: "login-test@example.com",
      password: "password123",
      terms_accepted_at: Time.current
    )
  end

  # ------------------------------------------------------------
  # 1. ログイン画面の表示（GET /session/new）
  # ------------------------------------------------------------
  describe "GET /session/new" do
    it "ログイン画面が正常に表示される" do
      get new_session_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("おかえりなさい")
    end

    context "ログイン済みの場合" do
      before do
        post session_path, params: { email_address: user.email_address, password: "password123" }
      end

      it "ホーム画面へリダイレクトされる" do
        get new_session_path

        expect(response).to redirect_to(root_path)
      end
    end
  end

  # ------------------------------------------------------------
  # 2. ログインの実行（POST /session）
  # ------------------------------------------------------------
  describe "POST /session" do
    context "正しいメールアドレスとパスワードの場合" do
      it "ログインが成功し、セッションCookieが発行されてホームへ遷移する" do
        post session_path, params: { email_address: user.email_address, password: "password123" }

        # ホーム画面へリダイレクトされること
        expect(response).to redirect_to(root_path)
        # Rails 8 のセッション Cookie が存在すること
        expect(cookies[:session_id]).to be_present
      end
    end

    context "パスワードが間違っている場合" do
      it "ログインに失敗し、ログイン画面へリダイレクトされてエラーメッセージが設定される" do
        post session_path, params: { email_address: user.email_address, password: "wrong-password" }

        # ログイン画面へリダイレクトされること（302 Found）
        expect(response).to redirect_to(new_session_path)
        # flash[:alert] にエラーメッセージが格納されていること
        expect(flash[:alert]).to be_present
        # セッション Cookie は発行されないこと
        expect(cookies[:session_id]).to be_blank
      end
    end
  end

  # ------------------------------------------------------------
  # 3. ログアウトの実行（DELETE /session）
  # ------------------------------------------------------------
  describe "DELETE /session" do
    before do
      # あらかじめログインしておく
      post session_path, params: { email_address: user.email_address, password: "password123" }
    end

    it "ログアウトが成功し、セッションCookieが破棄されてログイン画面へ遷移する" do
      delete session_path

      # ログアウト後はログイン画面へリダイレクト
      expect(response).to redirect_to(new_session_path)
      # セッション Cookie が削除されていること
      expect(cookies[:session_id]).to be_blank
    end
  end
end
