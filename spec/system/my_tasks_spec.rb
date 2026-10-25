require "rails_helper"

RSpec.describe "S-5 マイタスク", :js do
  before do
    travel_to(Time.zone.local(2026, 6, 20, 10, 0))
    visit "/tasks"
  end

  def row(title)
    find("section li[data-done]", text: title)
  end

  def trigger_of(title)
    find("button[aria-haspopup='menu'][aria-label='「#{title}」のメニュー']")
  end

  describe "行メニュー" do
    it "開いても遷移せず、見た目のみの項目を押すと閉じてトリガーへフォーカスが戻る" do
      trigger = trigger_of("見積もり作成")
      trigger.click

      expect(trigger["aria-expanded"]).to eq "true"
      expect(page).to have_css("##{trigger['aria-controls']} [role='menuitem']:focus", text: "編集")
      expect(page).to have_current_path("/tasks")

      find("##{trigger['aria-controls']} [role='menuitem']", text: "削除").click
      expect(trigger["aria-expanded"]).to eq "false"
      expect(page).to have_css("button[aria-label='「見積もり作成」のメニュー']:focus")
      expect(page).to have_current_path("/tasks")
      expect(page).to have_css("h1", text: "マイタスク")
    end

    it "行ごとに別のメニューが開き、Esc で閉じる" do
      trigger_of("起案書作成").click
      menu = find("##{trigger_of('起案書作成')['aria-controls']}")
      expect(menu).to be_visible
      expect(page).to have_css("[role='menu']", visible: true, count: 1)

      page.send_keys(:escape)
      expect(page).to have_no_css("section [role='menu']", visible: true)
      expect(page).to have_current_path("/tasks")
    end
  end

  # 要素の矩形 r を基準にした位置（x・y は r を使う JS の式）を実際のマウスで押す。
  # どの要素が受けるかはブラウザの当たり判定に任せる
  def click_at(element_js, x, y)
    point = page.evaluate_script(<<~JS)
      (() => {
        const el = #{element_js}
        el.scrollIntoView({ block: "center" })
        const r = el.getBoundingClientRect()
        return [r.left + (#{x}), r.top + (#{y})]
      })()
    JS
    page.driver.browser.mouse.click(x: point[0], y: point[1])
  end

  def row_js(title)
    %(Array.from(document.querySelectorAll("section li[data-done]")).find((li) => li.textContent.includes(#{title.to_json})))
  end

  describe "キーボード操作" do
    # カードの box-shadow に 2px のリングがあるか。カードは transition 付きなので、変化し終わるまで待つ
    def expect_ring(element, present:)
      page.document.synchronize do
        shadow = page.evaluate_script("getComputedStyle(arguments[0]).boxShadow", element)
        ringed = shadow.include?("0px 0px 0px 2px")
        raise Capybara::ExpectationNotMet, "box-shadow: #{shadow}" unless ringed == present

        true
      end
    end

    it "行のリンクにフォーカスするとカード全体をリングで囲み、メニューへのフォーカスでは囲まない" do
      card = row("見積もり作成")
      expect_ring(card, present: false)

      # キーボード操作（Tab）でのフォーカスにする（:focus-visible）
      trigger_of("経費申請").click
      page.send_keys(:escape)
      page.send_keys(:tab)
      expect(page).to have_css("section li[data-done] > a:focus", text: "見積もり作成")
      expect_ring(card, present: true)

      page.send_keys(:tab)
      expect(trigger_of("見積もり作成")).to match_css(":focus")
      expect_ring(card, present: false)
    end
  end

  describe "タスク詳細への遷移" do
    it "カードの余白（左右・上下の padding）を押しても S-4 へ移り、行の期限を引き継ぐ" do
      [ %w[8 r.height/2], %w[r.width/2 6], %w[r.width/3 r.height-6], %w[r.width-8 8] ].each do |x, y|
        visit "/tasks"
        click_at(row_js("見積もり作成"), x, y)

        expect(page).to have_css("h1", text: "見積もり作成")
        expect(page).to have_css("[data-parent-due]", text: "今日 18:00")
      end
    end

    it "メニューのトリガーと開いた項目はリンクより前面にあり、押しても遷移しない" do
      trigger = trigger_of("見積もり作成")
      click_at(%(document.querySelector("button[aria-label='「見積もり作成」のメニュー']")), "r.width/2", "r.height/2")
      expect(trigger["aria-expanded"]).to eq "true"
      expect(page).to have_current_path("/tasks")

      # 開いたメニューは次の行のカードに重なっても前面にある
      menu_id = trigger["aria-controls"]
      on_top = page.evaluate_script(<<~JS)
        Array.from(document.querySelectorAll("##{menu_id} [role='menuitem']")).every((item) => {
          const r = item.getBoundingClientRect()
          return document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2)?.closest("[role='menuitem']") === item
        })
      JS
      expect(on_top).to be true

      click_at(%(document.querySelector("##{menu_id} [role='menuitem']:last-child")), "r.width/2", "r.height/2")
      expect(trigger["aria-expanded"]).to eq "false"
      expect(page).to have_current_path("/tasks")
    end

    it "分解失敗の行を開くと S-4 も分解失敗で表示する" do
      within(row("引っ越しの準備をする")) { find("a").click }

      expect(page).to have_css("h1", text: "引っ越しの準備をする")
      expect(page).to have_css("[data-decomposition-status='failed']")
      expect(page).to have_text("分解に失敗しました。再度お試しください")
    end
  end

  describe "完了フィルタ" do
    it "トグルで全完了の親タスクとその日付見出しが現れ、戻すと見出しごと隠れる" do
      expect(page).to have_no_css("section h2", text: "6/23")
      expect(page).to have_no_text("経費精算の締め確認")
      expect(page).to have_css("section h2", text: "今日")

      click_on "完了済みを表示"
      expect(page).to have_css("section h2", text: "6/23")
      expect(row("経費精算の締め確認")).to be_visible

      click_on "完了済みを隠す"
      expect(page).to have_no_css("section h2", text: "6/23")
      expect(page).to have_no_text("経費精算の締め確認")
    end

    it "すべての親タスクが完了済みで隠れると空状態を出し、トグルで一覧に戻る" do
      expect(page).to have_no_text("表示できるタスクはありません")

      # 全行完了の状態はサンプルに無いため、画面上で全行を完了扱いにしてから検証する
      page.execute_script(<<~JS)
        document.querySelectorAll("section li[data-done]").forEach((el) => { el.dataset.done = "true" })
      JS
      expect(page).to have_text("表示できるタスクはありません")
      expect(page).to have_no_css("section h2")
      expect(page).to have_no_text("見積もり作成")

      click_on "完了済みを表示"
      expect(page).to have_no_text("表示できるタスクはありません")
      expect(page).to have_css("section h2", count: 5)
      expect(row("見積もり作成")).to be_visible
    end
  end

  describe "空状態" do
    it "タスクが無いときはタスクを作るから S-3 へ進める" do
      visit "/tasks?empty=1"

      expect(page).to have_text("まだタスクがありません")
      expect(page).to have_no_text("表示できるタスクはありません")
      within("[data-my-tasks-empty]") { click_on "タスクを作る" }
      expect(page).to have_current_path("/")
    end
  end
end
