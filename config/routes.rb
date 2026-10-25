Rails.application.routes.draw do
  # 画面モック（Figma モックを Rails のビューで再現したもの。ロジックは未実装）
  root "mocks#new_task"
  get "tasks" => "mocks#my_tasks", as: :my_tasks_mock
  get "tasks/sample" => "mocks#task_detail", as: :task_detail_mock
  get "signup" => "mocks#signup", as: :signup_mock
  get "login" => "mocks#login", as: :login_mock

  get "up" => "rails/health#show", as: :rails_health_check
end
