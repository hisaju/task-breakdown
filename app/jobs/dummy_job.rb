class DummyJob < ApplicationJob
  queue_as :default

def perform(*args)
    Rails.logger.info "=========================================="
    Rails.logger.info "ダミージョブが本番環境で正常に実行されました！"
    Rails.logger.info "=========================================="
  end
end
