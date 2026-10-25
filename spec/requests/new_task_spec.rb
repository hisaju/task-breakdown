require "rails_helper"

RSpec.describe "S-3 タスクを作る（画面モック）" do
  before do
    travel_to(Time.zone.local(2026, 6, 20, 10, 5, 30))
    get "/"
  end

  def html
    Nokogiri::HTML(response.body)
  end

  def form
    html.at_css("main form")
  end

  it "タスク詳細へ GET で送り、分解中の状態を hidden で渡す" do
    expect(form["action"]).to eq "/tasks/sample"
    expect(form["method"]).to eq "get"

    status = form.at_css("input[type='hidden'][name='status']")
    expect(status["value"]).to eq "decomposing"
    # 送信順は title → status → due（URL は /tasks/sample?title=…&status=decomposing&due=…）
    expect(form.css("[name]").map { it["name"] }).to eq %w[title status due]
  end

  it "自由文は必須・最大 200 文字で、背景や制約も書けることをプレースホルダで示す" do
    textarea = form.at_css("textarea[name='title']")

    expect(textarea).to have_attribute("required")
    expect(textarea["maxlength"]).to eq "200"
    expect(textarea["placeholder"]).to eq "例：来週の経営会議に向けて、新規事業の提案資料を作りたい（背景や制約も書けます）"
  end

  it "期限は任意の日時入力で、下限は現在時刻（分単位）" do
    due = form.at_css("input[name='due']")

    expect(due["type"]).to eq "datetime-local"
    expect(due["min"]).to eq "2026-06-20T10:05"
    expect(due).not_to have_attribute("required")
    expect(html.at_css("label[for='#{due['id']}']").text.strip).to eq "期限（任意）"
  end

  it "ショートカットは Mac と Windows の両方を表記し、フォーム全体で受け付ける" do
    expect(form.text).to include("⌘ / Ctrl + Enter で送信")
    expect(form.text).not_to include("⌘ + Enter で送信")
    expect(form["data-action"]).to include("keydown->prompt#submitOnShortcut")
  end

  it "最大 200 文字であることを入力欄の下に表示し、入力欄の説明として読み上げる" do
    textarea = form.at_css("textarea[name='title']")
    hint = form.at_css("##{textarea['aria-describedby']}")

    expect(hint.text.strip).to eq "200 文字まで"
  end
end
