require "rails_helper"

RSpec.describe "shared/_empty_state" do
  def doc
    Nokogiri::HTML.fragment(rendered)
  end

  it "アイコン・見出し・補足・アクションを表示する" do
    render partial: "shared/empty_state",
           locals: { icon: :inbox, title: "まだタスクがありません", body: "やりたいことを入力すると、AI が手順に分解します。",
                     action: { label: "タスクを作る", href: "/" } }

    expect(doc.at_css("svg")).to be_present
    expect(doc.at_css("h2").text.strip).to eq "まだタスクがありません"
    expect(doc.text).to include("やりたいことを入力すると、AI が手順に分解します。")
    link = doc.at_css("a[href='/']")
    expect(link.text.strip).to eq "タスクを作る"
  end

  it "補足とアクションは省略でき、data 属性と hidden を渡せる" do
    render partial: "shared/empty_state",
           locals: { icon: :inbox, title: "表示できるタスクはありません",
                     data: { completed_filter_target: "empty" }, hidden: true }

    root = doc.element_children.first
    expect(root["data-completed-filter-target"]).to eq "empty"
    expect(root["hidden"]).not_to be_nil
    expect(doc.css("a")).to be_empty
    expect(doc.css("p")).to be_empty
  end
end
