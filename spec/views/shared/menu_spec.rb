require "rails_helper"

RSpec.describe "shared/_menu" do
  def doc
    Nokogiri::HTML.fragment(rendered)
  end

  let(:items) do
    [ { label: "編集" }, { label: "削除", danger: true }, { label: "ログアウト", href: "/login" } ]
  end

  it "トリガーは aria-haspopup・aria-expanded・aria-controls を持ち、メニューの id と対応する" do
    render partial: "shared/menu", locals: { id: "task-menu", items:, label: "タスクのメニュー" }

    trigger = doc.at_css("button[aria-haspopup='menu']")
    expect(trigger["type"]).to eq "button"
    expect(trigger["aria-expanded"]).to eq "false"
    expect(trigger["aria-controls"]).to eq "task-menu"
    expect(trigger["aria-label"]).to eq "タスクのメニュー"
    menu = doc.at_css("#task-menu")
    expect(menu["role"]).to eq "menu"
    expect(menu["hidden"]).not_to be_nil
    expect(doc.at_css("[data-controller='menu']")).to be_present
  end

  it "href の無い項目は no-op ボタン、href のある項目はリンクになり、削除は danger" do
    render partial: "shared/menu", locals: { id: "m", items: }

    edit, delete, logout = doc.css("[role='menuitem']").to_a
    expect(edit.name).to eq "button"
    expect(edit["type"]).to eq "button"
    expect(edit["data-mock"]).to eq "noop"
    expect(edit["class"]).not_to include("text-danger")
    expect(delete["data-mock"]).to eq "noop"
    expect(delete["class"]).to include("text-danger")
    expect(logout.name).to eq "a"
    expect(logout["href"]).to eq "/login"
    expect(logout["data-mock"]).to be_nil
    expect(doc.css("[role='menuitem']").map { it["tabindex"] }).to all(eq "-1")
  end

  it "見た目のみの項目は押すとメニューを閉じ、フォーカスが外へ出ても閉じる" do
    render partial: "shared/menu", locals: { id: "m", items: }

    expect(doc.css("[data-mock='noop']").map { it["data-action"] }).to all(eq "menu#closeAndFocus")
    expect(doc.at_css("a[role='menuitem']")["data-action"]).to be_nil
    expect(doc.at_css("[data-controller='menu']")["data-action"]).to include("focusout->menu#closeOnFocusOut")
  end

  it "placement で下向き（既定）と上向きを切り替える" do
    render partial: "shared/menu", locals: { id: "down", items: }
    expect(doc.at_css("#down")["class"]).to include("top-full")

    render partial: "shared/menu", locals: { id: "up", items:, placement: :up }
    expect(doc.at_css("#up")["class"]).to include("bottom-full")
    expect(doc.at_css("#up")["class"]).not_to include("top-full")
  end
end
