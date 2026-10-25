require "rails_helper"

RSpec.describe "shared/_task_progress" do
  def doc
    Nokogiri::HTML.fragment(rendered)
  end

  it "n/m 完了と完了率の幅のバーを表示する" do
    render partial: "shared/task_progress", locals: { done: 2, total: 4 }

    expect(doc.at_css("[data-task-progress]").text.squish).to eq "2/4 完了"
    expect(doc.at_css("[style]")["style"]).to include("width: 50%")
  end

  it "total が 0 のときは「—」だけを表示する" do
    render partial: "shared/task_progress", locals: { done: 0, total: 0 }

    expect(doc.at_css("[data-task-progress]").text.squish).to eq "—"
    expect(doc.at_css("[style]")).to be_nil
  end
end
