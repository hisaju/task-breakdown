require "rails_helper"

RSpec.describe "S-3 タスクを作る", :js do
  before do
    travel_to(Time.zone.local(2026, 6, 20, 10, 0))
    visit root_path
  end

  let(:textarea) { find("textarea[name='title']") }

  def press_shortcut(element)
    element.send_keys([ :control, :enter ])
  end

  # ブラウザの制約検証で送信が止まっていること（URL がホームのまま、入力欄が不正）
  def expect_not_submitted
    sleep 0.3
    expect(page).to have_current_path("/")
    expect(page.evaluate_script("document.querySelector('textarea[name=title]').validity.valid")).to be false
  end

  it "空欄では送信ボタンでも Ctrl + Enter でも送信されない" do
    click_on "タスクを分解する"
    expect_not_submitted

    press_shortcut(textarea)
    expect_not_submitted
  end

  it "空白だけの入力は送信されず、文字を入れると送信できる" do
    textarea.fill_in(with: "   ")
    click_on "タスクを分解する"
    expect_not_submitted
    expect(page.evaluate_script("document.querySelector('textarea[name=title]').validationMessage"))
      .to eq "取り組みたいことを入力してください"

    textarea.fill_in(with: "経費申請")
    click_on "タスクを分解する"
    expect(page).to have_current_path(%r{\A/tasks/sample\?})
  end

  it "入力例チップで空白を置き換えても送信できる" do
    textarea.fill_in(with: "  ")
    click_on "引っ越しの準備をする"
    click_on "タスクを分解する"

    expect(page).to have_current_path(%r{\A/tasks/sample\?})
  end

  it "200 文字を超えて入力できない" do
    textarea.fill_in(with: "あ" * 201)

    expect(textarea.value.length).to eq 200
  end

  it "期限を入れて送信すると、分解中のタスク詳細に親タスク名と期限が引き継がれる" do
    textarea.fill_in(with: "経費申請")
    fill_in "期限（任意）", with: "2026-06-26T17:00"
    click_on "タスクを分解する"

    expect(page).to have_current_path(
      "/tasks/sample?title=#{CGI.escape('経費申請')}&status=decomposing&due=#{CGI.escape('2026-06-26T17:00')}"
    )
    expect(page).to have_css("[data-decomposition-status='decomposing']")
    expect(page).to have_css("h1", text: "経費申請")
    expect(find("[data-parent-due]").text.strip).to eq "6/26 17:00"
  end

  it "期限を入れずに送信すると、タスク詳細は「期限なし」になる" do
    textarea.fill_in(with: "経費申請")
    press_shortcut(textarea)

    expect(page).to have_current_path(%r{status=decomposing&due=\z})
    expect(find("[data-parent-due]").text.strip).to eq "期限なし"
  end

  it "期限の入力欄にいても Ctrl + Enter で送信できる" do
    textarea.fill_in(with: "経費申請")
    due = find_field("期限（任意）")
    due.fill_in(with: "2026-06-26T17:00")
    press_shortcut(due)

    expect(page).to have_current_path(%r{status=decomposing&due=2026-06-26T17%3A00\z})
  end

  it "過去の日時は期限にできない" do
    textarea.fill_in(with: "経費申請")
    fill_in "期限（任意）", with: "2026-06-19T17:00"
    click_on "タスクを分解する"

    sleep 0.3
    expect(page).to have_current_path("/")
    expect(page.evaluate_script("document.querySelector('input[name=due]').validity.rangeUnderflow")).to be true
  end
end
