class TasksController < ApplicationController
  # タスク作成画面（S-3）の表示
  def new
    @task = Task.new
  end

  # タスク作成の保存処理
  def create
    # ログイン中のユーザーに紐づくタスクを作成
    @task = Current.user.tasks.build(task_params)

    if @task.save
      # 保存成功時：詳細画面（モック詳細）へ移動
      redirect_to task_detail_mock_path, notice: t(".success")
    else
      # 保存失敗時：入力内容を残したまま同じ画面を再表示
      flash.now[:alert] = t(".failure")
      render :new, status: :unprocessable_entity
    end
  end

  private

  # 安全のために受け取る項目（タイトル・期限）を制限
  def task_params
    params.expect(task: [ :title, :due_at ])
  end
end
