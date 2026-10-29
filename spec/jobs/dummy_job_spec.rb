require 'rails_helper'

RSpec.describe DummyJob do
  include ActiveJob::TestHelper

  it "ダミージョブがエンキューされ、正常に実行されること" do
    # 1. キューに正しく追加（エンキュー）されるかの確認
    expect {
      described_class.perform_later
    }.to have_enqueued_job(described_class)

    # 2. 直接実行してエラーが起きないかの確認
    expect {
      described_class.perform_now
    }.not_to raise_error
  end
end
