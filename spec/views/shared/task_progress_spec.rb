require "rails_helper"

RSpec.describe "shared/_task_progress" do
  def doc
    Nokogiri::HTML.fragment(rendered)
  end

  def root
    doc.at_css("[data-task-progress]")
  end

  it "n/m 完了と完了率の幅のバーを表示し、progressbar として値を持つ" do
    render partial: "shared/task_progress", locals: { done: 2, total: 4 }

    expect(root.text.squish).to eq "2/4 完了"
    expect(doc.at_css("[data-task-progress-bar]")["style"]).to include("width: 50%")
    expect(doc.at_css("[data-task-progress-track]")["hidden"]).to be_nil
    expect(root["role"]).to eq "progressbar"
    expect(root["aria-label"]).to eq "進捗"
    expect([ root["aria-valuemin"], root["aria-valuenow"], root["aria-valuemax"] ]).to eq %w[0 2 4]
  end

  it "total が 0 のときは「—」だけを表示し、バーは隠して progressbar にしない" do
    render partial: "shared/task_progress", locals: { done: 0, total: 0 }

    expect(root.text.squish).to eq "—"
    expect(doc.at_css("[data-task-progress-track]")["hidden"]).not_to be_nil
    expect(root["role"]).to be_nil
    expect(root["aria-valuenow"]).to be_nil
  end
end
