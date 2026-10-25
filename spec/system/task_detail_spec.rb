require "rails_helper"

RSpec.describe "S-4 タスク詳細", :js do
  before do
    travel_to(Time.zone.local(2026, 6, 20, 10, 0))
  end

  def card(title)
    find("ol[data-subtasks-target='list'] > li", text: title)
  end

  def check_of(title)
    find("ol [data-subtask-card-target='check'][aria-label^='「#{title}」']")
  end

  def progress_text
    find("[data-task-progress]").text.squish
  end

  def line_through?(title)
    page.evaluate_script(<<~JS)
      getComputedStyle(Array.from(document.querySelectorAll("ol [data-subtask-card-target='title']"))
        .find((el) => el.textContent.trim() === #{title.to_json})).textDecorationLine.includes("line-through")
    JS
  end

  describe "分解中からの自動遷移" do
    it "分解中で開くと 5 秒以内に分解完了とサブタスクが表示され、戻るで分解中に戻らない" do
      visit "/tasks"
      visit "/tasks/sample?status=decomposing&title=#{CGI.escape('経費申請')}"
      expect(page).to have_css("[data-decomposition-status='decomposing']")
      expect(page).to have_css("[data-skeleton]")

      expect(page).to have_css("[data-decomposition-status='done']", wait: 5)
      expect(page).to have_text("目的と読み手を整理する")
      expect(page).to have_css("h1", text: "経費申請")
      expect(page).to have_no_css("[data-skeleton]")

      page.go_back
      expect(page).to have_current_path("/tasks")
    end

    it "autoplay=0 では分解中のまま遷移しない" do
      visit "/tasks/sample?status=decomposing&autoplay=0"
      expect(page).to have_css("[data-decomposition-status='decomposing']")

      sleep 3.5
      expect(page).to have_css("[data-decomposition-status='decomposing']")
      expect(page).to have_current_path("/tasks/sample?status=decomposing&autoplay=0")
    end
  end

  describe "親タスクのメニュー" do
    let(:trigger) { find("button[aria-controls='task-menu']") }

    def focused_item
      page.evaluate_script("document.activeElement.textContent").strip
    end

    before do
      visit "/tasks/sample"
    end

    it "開くと最初の項目にフォーカスし、↑↓・Home・End で項目を移動できる" do
      trigger.click
      expect(page).to have_css("#task-menu [role='menuitem']:focus", text: "編集")

      page.send_keys(:down)
      expect(focused_item).to eq "再分解"
      page.send_keys(:end)
      expect(focused_item).to eq "削除"
      page.send_keys(:down)
      expect(focused_item).to eq "編集"
      page.send_keys(:up)
      expect(focused_item).to eq "削除"
      page.send_keys(:home)
      expect(focused_item).to eq "編集"
    end

    it "Esc で閉じてトリガーにフォーカスが戻る" do
      trigger.click
      expect(page).to have_css("#task-menu", visible: true)

      page.send_keys(:escape)
      expect(page).to have_no_css("#task-menu", visible: true)
      expect(trigger["aria-expanded"]).to eq "false"
      expect(page).to have_css("button[aria-controls='task-menu']:focus")
    end

    it "外側のクリックで閉じる" do
      trigger.click
      expect(page).to have_css("#task-menu", visible: true)

      find("h1").click
      expect(page).to have_no_css("#task-menu", visible: true)
    end

    it "Tab でメニューの外へフォーカスが出ると閉じる" do
      trigger.click
      expect(page).to have_css("#task-menu [role='menuitem']:focus")

      page.send_keys(:tab)
      expect(page).to have_no_css("#task-menu", visible: true)
      expect(trigger["aria-expanded"]).to eq "false"
    end

    it "見た目のみの項目を押すと何も起きずに閉じる" do
      trigger.click
      find("#task-menu [role='menuitem']", text: "再分解").click

      expect(page).to have_no_css("#task-menu", visible: true)
      expect(page).to have_current_path("/tasks/sample")
      expect(page).to have_css("button[aria-controls='task-menu']:focus")
    end
  end

  describe "タスクを追加" do
    it "3 回追加すると番号が続き、id が重複せず、追加カードのメニューも開ける" do
      visit "/tasks/sample"

      3.times { click_on "タスクを追加" }

      numbers = all("ol [data-subtask-number]", visible: :all).map { it.text(:all).strip }
      expect(numbers).to eq %w[01 02 03 04 05 06 07 08 09]
      ids = page.evaluate_script("Array.from(document.querySelectorAll('[id]')).map((el) => el.id)")
      expect(ids).to eq ids.uniq
      expect(ids).to include("subtask-menu-07", "subtask-menu-08", "subtask-menu-09")
      expect(page).to have_no_css("ol [id*='__NUMBER__']", visible: :all)

      find("button[aria-controls='subtask-menu-09']").click
      expect(page).to have_css("#subtask-menu-09 [role='menuitem']", text: "期限設定")
      expect(progress_text).to eq "1/9 完了"
    end

    it "分解失敗の画面でも追加でき、進捗が「—」から n/m 完了に変わる" do
      visit "/tasks/sample?status=failed"
      expect(progress_text).to eq "—"

      click_on "タスクを追加"
      expect(page).to have_css("ol [data-subtask-number]", text: "01")
      expect(progress_text).to eq "0/1 完了"
      expect(page).to have_css("[data-task-progress][role='progressbar'][aria-valuemax='1']")
    end
  end

  describe "完了チェック" do
    it "完了にすると消え、表示すると打ち消し線付きで現れ、未完了に戻せる（進捗も連動する）" do
      visit "/tasks/sample"
      expect(progress_text).to eq "1/6 完了"

      check_of("目的と読み手を整理する").click
      expect(page).to have_no_text("目的と読み手を整理する")
      expect(progress_text).to eq "2/6 完了"
      expect(page).to have_css("[data-task-progress][aria-valuenow='2'][aria-valuemax='6']")
      # 消えたカードの代わりに次の完了チェックへフォーカスが移る
      expect(page).to have_css("[data-subtask-card-target='check'][aria-label^='「必要な情報を集める」']:focus")

      click_on "完了済みを表示"
      expect(card("目的と読み手を整理する")["data-done"]).to eq "true"
      expect(line_through?("目的と読み手を整理する")).to be true
      expect(check_of("目的と読み手を整理する")["aria-label"]).to eq "「目的と読み手を整理する」を未完了に戻す"

      check_of("目的と読み手を整理する").click
      expect(card("目的と読み手を整理する")["data-done"]).to eq "false"
      expect(line_through?("目的と読み手を整理する")).to be false
      expect(check_of("目的と読み手を整理する")["aria-label"]).to eq "「目的と読み手を整理する」を完了にする"
      expect(progress_text).to eq "1/6 完了"

      numbers = all("ol [data-subtask-number]").map { it.text.strip }
      expect(numbers).to eq %w[01 02 03 04 05 06]
    end

    it "最初から完了済みのカードも打ち消し線付きで表示され、1 回のクリックで未完了に戻る" do
      visit "/tasks/sample"
      click_on "完了済みを表示"

      title = "依頼の背景と締め切りを確認する"
      expect(line_through?(title)).to be true
      expect(check_of(title)["aria-label"]).to eq "「#{title}」を未完了に戻す"

      check_of(title).click
      expect(line_through?(title)).to be false
      expect(check_of(title)["aria-label"]).to eq "「#{title}」を完了にする"

      click_on "完了済みを隠す"
      expect(page).to have_text(title)
    end

    it "すべて完了にすると全完了の空状態が出て、完了済みを表示すると消える" do
      visit "/tasks/sample"
      expect(page).to have_no_text("すべての手順が完了しました")

      %w[目的と読み手を整理する 必要な情報を集める 上長に方向性を確認する 初稿を作成する 提出後に振り返りをメモする].each do |title|
        check_of(title).click
        expect(page).to have_no_text(title)
      end

      expect(page).to have_text("すべての手順が完了しました")
      expect(page).to have_link("マイタスクへ", href: "/tasks")
      expect(progress_text).to eq "6/6 完了"

      click_on "完了済みを表示"
      expect(page).to have_no_text("すべての手順が完了しました")
      expect(page).to have_text("初稿を作成する")
    end

    it "all_done=1 では最初から全完了の空状態を表示する" do
      visit "/tasks/sample?status=done&all_done=1"

      expect(page).to have_text("すべての手順が完了しました")
      expect(progress_text).to eq "6/6 完了"
    end

    it "日付の絞り込みで見えている手順が完了して 0 件になっても、全完了の空状態は出さない" do
      visit "/tasks/sample"
      # 日付タブ「明日」で絞り込んだ状態を再現する（明日以外のカードに data-hidden-by-tab を付ける）
      page.execute_script(<<~JS)
        document.querySelectorAll("ol > li[data-due-key]").forEach((li) => {
          li.toggleAttribute("data-hidden-by-tab", li.dataset.dueKey !== "tomorrow")
        })
      JS
      expect(page).to have_text("上長に方向性を確認する")

      check_of("上長に方向性を確認する").click
      expect(page).to have_no_text("上長に方向性を確認する")
      expect(page).to have_no_text("すべての手順が完了しました")
    end
  end
end
