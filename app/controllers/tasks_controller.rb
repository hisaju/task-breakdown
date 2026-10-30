class TasksController < ApplicationController
  include DueDateHelper

  # マイタスク一覧（S-5）の表示
  def index
    # ログイン中ユーザーの親タスクを期限順で取得（サブタスクもまとめて取得してN+1を防止）
    tasks = Current.user.tasks.roots.ordered_by_due.includes(:children)

    # 日付見出しごと（今日・明日・M/D・期限なし）にグループ化
    @grouped_tasks = tasks.group_by { |task| due_label(task.due_at, date_only: true) }
  end

  # タスク作成画面（S-3）の表示
  def new
    @task = Task.new
  end

  # タスク作成の保存処理
  def create
    @task = Current.user.tasks.build(task_params)

    if @task.save
      redirect_to task_detail_mock_path, notice: t(".success")
    else
      flash.now[:alert] = t(".failure")
      render :new, status: :unprocessable_entity
    end
  end

  private

  def task_params
    params.expect(task: [ :title, :due_at ])
  end
end
