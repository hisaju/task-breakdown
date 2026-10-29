require 'rails_helper'

RSpec.describe DummyJob do
  include ActiveJob::TestHelper

  it "ダミージョブがエンキューされ、正常に実行されること" do
    expect {
      described_class.perform_later
    }.to have_enqueued_job(described_class)

    perform_enqueued_jobs do
      expect {
        described_class.perform_now
      }.not_to raise_error
    end
  end
end
