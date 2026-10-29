Rails.application.routes.draw do
  # 画面モック（Figma モックを Rails のビューで再現したもの。ロジックは未実装）
  root "mocks#new_task"
  get "tasks" => "mocks#my_tasks", as: :my_tasks_mock
  get "tasks/sample" => "mocks#task_detail", as: :task_detail_mock
  get "signup" => "mocks#signup", as: :signup_mock
  post "signup" => "mocks#signup_submit"
  get "login" => "mocks#login", as: :login_mock
  post "login" => "mocks#login_submit"
  get "terms" => "mocks#terms", as: :terms_mock
  get "privacy" => "mocks#privacy", as: :privacy_mock

  get "up" => "rails/health#show", as: :rails_health_check

  # --- ここから追加 ---
  # 本番でのSolid Queue動作確認用の仮ルート（確認が終わったら削除してOKです）
  get "/test_job", to: proc {
    DummyJob.perform_later
    [ 200, { "Content-Type" => "text/plain; charset=utf-8" }, [ "ジョブをエンキューしました！Renderのログを確認してください。" ] ]
  }
  # --- ここまで追加 ---
end
