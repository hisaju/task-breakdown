class DummyJob < ApplicationJob
  queue_as :default

  def perform
    # ログに出力して成功を確認しやすくする
    Rails.logger.info "========================================"
    Rails.logger.info "ダミージョブがSolid Queueで正常に実行されました！"
    Rails.logger.info "========================================"
  end
end
