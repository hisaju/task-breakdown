require "rails_helper"

RSpec.describe "会員登録（本番機能）" do
  # ------------------------------------------------------------
  # 1. 会員登録画面の表示（GET /registration/new）
  # ------------------------------------------------------------
  describe "GET /registration/new" do
    it "会員登録画面が正常に表示される" do
      get new_registration_path

      # 200 OK で正しく画面が返ってきていること
      expect(response).to have_http_status(:ok)
      # 画面内にモックと同じ見出しが含まれていること
      expect(response.body).to include("アカウントを作成する")
    end
  end

  # ------------------------------------------------------------
  # 2. 会員登録の実行（POST /registration）
  # ------------------------------------------------------------
  describe "POST /registration" do
    # 正常系のベースとなる送信データ（let: 各テストから参照できる共通変数）
    let(:valid_params) do
      {
        user: {
          name: "テストユーザー",
          email_address: "test@example.com",
          password: "password123",
          password_confirmation: "password123",
          terms_of_service: "1" # コントローラで terms_accepted_at に変換されるキー
        }
      }
    end

    context "有効なパラメータの場合" do
      it "ユーザーが作成され、ログイン状態になってホームへリダイレクトされる" do
        # post 前後で User レコードの件数が +1 増えることを検証
        expect {
          post registration_path, params: valid_params
        }.to change(User, :count).by(1)

        # 登録後は自動ログインしてホーム画面（/）へ遷移すること
        expect(response).to redirect_to(root_path)
        # Rails 8 認証のセッション Cookie が発行されていること
        expect(cookies[:session_id]).to be_present
      end
    end

    context "無効なパラメータの場合" do
      it "パスワードが8文字未満だと登録できず 422 が返る" do
        # deep_merge: パスワード部分だけを不正な値（短小）に上書き
        invalid_params = valid_params.deep_merge(user: { password: "short", password_confirmation: "short" })

        # バリデーションエラー時は DB の件数が変化しないこと
        expect {
          post registration_path, params: invalid_params
        }.not_to change(User, :count)

        # Turbo でエラー表示を再描画するため、422（Unprocessable Content）が返ること
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "利用規約に未同意だと登録できず 422 が返る" do
        # 規約チェックを「未同意（0）」に上書き
        invalid_params = valid_params.deep_merge(user: { terms_of_service: "0" })

        expect {
          post registration_path, params: invalid_params
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  # ------------------------------------------------------------
  # 3. ログイン済みユーザーのアクセス制御（フィルタの検証）
  # ------------------------------------------------------------
  describe "ログイン済みの場合のアクセス制御" do
    let(:user) do
      User.create!(
        name: "登録済みユーザー",
        email_address: "already@example.com",
        password: "password123",
        terms_accepted_at: Time.current
      )
    end

    before do
      # あらかじめログインセッションを作成しておく
      post session_path, params: { email_address: user.email_address, password: "password123" }
    end

    it "GET /registration/new にアクセスするとホームへリダイレクトされる" do
      get new_registration_path

      # ログイン済みなら登録画面を開けず、ホームへ押し戻されること（redirect_if_authenticated）
      expect(response).to redirect_to(root_path)
    end
  end
end
