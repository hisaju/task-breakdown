module Tasks
  class CompletionsController < ApplicationController
    before_action :set_task

    # 完了にする（POST /tasks/:task_id/completion）
    def create
      @task.complete!
      redirect_to tasks_path, status: :see_other
    end

    # 未完了に戻す（DELETE /tasks/:task_id/completion）
    def destroy
      @task.uncomplete!
      redirect_to tasks_path, status: :see_other
    end

    private

    # 防犯対策：自分のタスクの中からだけ探す
    def set_task
      @task = Current.user.tasks.find(params[:task_id])
    end
  end
end
