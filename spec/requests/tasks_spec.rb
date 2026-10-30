require "rails_helper"

RSpec.describe "タスク管理（作成・認可）" do
  # テスト全体で使うログインユーザー
  let!(:user) do
    User.create!(
      name: "テストユーザー",
      email_address: "task-test@example.com",
      password: "password123",
      terms_accepted_at: Time.current
    )
  end

  # ------------------------------------------------------------
  # 1. タスク作成画面の表示（GET /tasks/new または root_path）
  # ------------------------------------------------------------
  describe "GET /tasks/new" do
    context "未ログインの場合" do
      it "ログイン画面へリダイレクトされる" do
        get new_task_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "ログイン済みの場合" do
      before do
        post session_path, params: { email_address: user.email_address, password: "password123" }
      end

      it "タスク作成画面が正常に表示され、作成フォームが存在する" do
        get new_task_path

        # 200 OK で描画されること
        expect(response).to have_http_status(:ok)
        # 文言変更に影響されないよう、フォーム要素（action="/tasks"）の存在を検証
        expect(response.body).to include('action="/tasks"')
      end
    end
  end

  # ------------------------------------------------------------
  # 2. タスク作成の実行（POST /tasks）
  # ------------------------------------------------------------
  describe "POST /tasks" do
    context "未ログインの場合" do
      it "タスクは作成されず、ログイン画面へリダイレクトされる" do
        expect do
          post tasks_path, params: { task: { title: "未ログインタスク" } }
        end.not_to change(Task, :count)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "ログイン済みの場合" do
      before do
        post session_path, params: { email_address: user.email_address, password: "password123" }
      end

      context "有効なパラメータの場合" do
        let(:valid_params) do
          {
            task: {
              title: "新規事業の提案資料を作成する",
              due_at: 1.day.from_now.change(sec: 0)
            }
          }
        end

        it "タスクが作成され、ログイン中ユーザーに紐づいて詳細モックへリダイレクトされる" do
          # ログインユーザーのタスクとして 1件増えること
          expect do
            post tasks_path, params: valid_params
          end.to change(user.tasks, :count).by(1)

          # 属性が正しく保存されていること
          created_task = user.tasks.last
          expect(created_task.title).to eq("新規事業の提案資料を作成する")

          # 完了通知とともに詳細画面（モック詳細）へ遷移
          expect(response).to redirect_to(task_detail_mock_path)
          expect(flash[:notice]).to eq(I18n.t("tasks.create.success"))
        end
      end

      context "無効なパラメータの場合（タイトルが空欄）" do
        let(:invalid_params) do
          {
            task: {
              title: "",
              due_at: 1.day.from_now
            }
          }
        end

        it "タスクは作成されず、422 Unprocessable Entity で作成画面が再描画される" do
          expect do
            post tasks_path, params: invalid_params
          end.not_to change(Task, :count)

          expect(response).to have_http_status(:unprocessable_content)
          expect(flash.now[:alert]).to eq(I18n.t("tasks.create.failure"))
        end
      end

      context "無効なパラメータの場合（過去の期限日時）" do
        let(:past_params) do
          {
            task: {
              title: "過去日のタスク",
              due_at: 1.day.ago
            }
          }
        end

        it "タスクは作成されず、422 Unprocessable Entity が返る" do
          expect do
            post tasks_path, params: past_params
          end.not_to change(Task, :count)

          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end

  # ------------------------------------------------------------
  # 3. マイタスク一覧画面の表示（GET /tasks）
  # ------------------------------------------------------------
  describe "GET /tasks" do
    context "未ログインの場合" do
      it "ログイン画面へリダイレクトされる" do
        get tasks_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "ログイン済みの場合" do
      let!(:other_user) do
        User.create!(
          name: "他ユーザー",
          email_address: "other@example.com",
          password: "password123",
          terms_accepted_at: Time.current
        )
      end

      before do
        post session_path, params: { email_address: user.email_address, password: "password123" }

        # 自分のタスク
        user.tasks.create!(title: "自分の親タスク", due_at: 1.day.from_now)

        # 他人のタスク
        other_user.tasks.create!(title: "他人の親タスク", due_at: 1.day.from_now)
      end

      it "200 OK が返り、自分のタスクのみが表示され、他ユーザーのタスクは表示されない（AC-3）" do
        get tasks_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("自分の親タスク")
        expect(response.body).not_to include("他人の親タスク")
      end
    end
  end
end
