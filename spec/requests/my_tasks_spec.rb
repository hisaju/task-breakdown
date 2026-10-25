require "rails_helper"

RSpec.describe "S-5 マイタスク（画面モック）" do
  before do
    travel_to(Time.zone.local(2026, 6, 20, 10, 0))
  end

  def html
    Nokogiri::HTML(response.body)
  end

  def rows
    html.css("section li[data-done]")
  end

  def row(title)
    rows.find { it.at_css("a p.font-serif").text.strip == title }
  end

  def link_params(row)
    Rack::Utils.parse_query(URI.parse(row.at_css("a")["href"]).query)
  end

  describe "行の構造" do
    before { get "/tasks" }

    it "リンクの中にボタンを入れず、メニューはリンクの兄弟要素に置く" do
      expect(rows.size).to eq 6
      expect(html.css("a button")).to be_empty
      rows.each do |row|
        expect(row.css("a").size).to eq 1
        expect(row.at_css("a [aria-haspopup='menu']")).to be_nil
        expect(row.at_css("[data-controller='menu'] button[aria-haspopup='menu']")).to be_present
      end
    end

    it "リンクの中にタイトル・期限・ステータス・進捗を持つ" do
      link = row("見積もり作成").at_css("a")

      expect(link.at_css("p.font-serif").text.strip).to eq "見積もり作成"
      expect(link.at_css("time[datetime]").text.strip).to eq "今日 18:00"
      expect(link.at_css("[data-decomposition-status='done']")).to be_present
      expect(link.at_css("[data-task-progress]").text.squish).to eq "1/3 完了"
    end

    it "カードは S-4 のサブタスクカードと同じ体裁（余白・角丸・ホバーの影）" do
      rows.each do |row|
        expect(row["class"].split).to include("px-5", "py-5", "gap-4", "rounded-xl", "border-line", "hover:shadow-card")
      end
    end
  end

  describe "行メニュー" do
    before { get "/tasks" }

    it "編集・削除を見た目のみの項目で持ち、削除は danger" do
      rows.each do |row|
        items = row.css("[role='menuitem']")
        expect(items.map { it.text.strip }).to eq %w[編集 削除]
        expect(items.map(&:name)).to all(eq "button")
        expect(items.map { it["data-mock"] }).to all(eq "noop")
        expect(items.last["class"]).to include("text-danger")
      end
    end

    it "トリガーの aria-label に親タスク名を含み、メニューの id は行ごとに一意で aria-controls と対応する" do
      triggers = rows.map { it.at_css("button[aria-haspopup='menu']") }
      menu_ids = rows.map { it.at_css("[role='menu']")["id"] }

      expect(triggers.map { it["aria-label"] }).to eq(rows.map { "「#{it.at_css('a p.font-serif').text.strip}」のメニュー" })
      expect(menu_ids.uniq.size).to eq rows.size
      expect(triggers.map { it["aria-controls"] }).to eq menu_ids
      expect(html.css("[id]").map { it["id"] }.tally.select { |_, n| n > 1 }).to be_empty
    end
  end

  describe "タスク詳細への引き継ぎ" do
    before { get "/tasks" }

    it "行のリンクは親タスク名・分解ステータス・期限を渡す（期限なしは空の due）" do
      expect(link_params(row("経費申請"))).to eq("title" => "経費申請", "status" => "decomposing", "due" => "2026-06-20T17:00")
      expect(link_params(row("引っ越しの準備をする"))).to eq("title" => "引っ越しの準備をする", "status" => "failed", "due" => "")
      expect(link_params(row("社内提案資料を作成する")))
        .to eq("title" => "社内提案資料を作成する", "status" => "done", "due" => "2026-06-27T17:00")
      expect(rows.map { URI.parse(it.at_css("a")["href"]).path }).to all(eq "/tasks/sample")
    end

    it "どの行を開いても S-4 の親タスクの期限は行の期限と同じで、サブタスクの期限は親の期限を超えない" do
      targets = rows.map { [ it.at_css("a")["href"], it.at_css("a [data-row-due]").text.squish ] }
      expect(targets.size).to eq 6

      targets.each do |href, row_due|
        get href, params: { autoplay: "0" }
        expect(html.at_css("[data-parent-due]").text.squish).to eq(row_due), href

        parent_time = html.at_css("[data-parent-due] time")&.[]("datetime")
        next unless parent_time

        card_times = html.css("ol[data-subtasks-target='list'] > li time[datetime]").map { Time.zone.parse(it["datetime"]) }
        expect(card_times).to all(be <= Time.zone.parse(parent_time)), href
        tab_keys = html.css("[role='tab']").map { it["data-due-key"] } - [ "all" ]
        card_keys = html.css("ol[data-subtasks-target='list'] > li").map { it["data-due-key"] }.uniq - [ "none" ]
        expect(tab_keys).to match_array(card_keys), href
      end
    end

    it "リンク先の S-4 は行と同じステータスで開く" do
      href = row("引っ越しの準備をする").at_css("a")["href"]

      get href
      expect(html.at_css("[data-decomposition-status]")["data-decomposition-status"]).to eq "failed"
      expect(html.at_css("h1").text.strip).to eq "引っ越しの準備をする"
    end
  end

  describe "完了フィルタ" do
    before { get "/tasks" }

    it "全完了の親タスクは初期描画で隠し、打ち消し線のクラスを持つ" do
      done_row = row("経費精算の締め確認")

      expect(done_row["data-done"]).to eq "true"
      expect(done_row.key?("data-hidden-by-done")).to be true
      expect(done_row.at_css("a p.font-serif")["class"]).to include("line-through")
    end

    it "表示対象が全完了の親タスクだけの日付グループは見出しごと隠し、それ以外のグループは隠さない" do
      groups = html.css("section[data-completed-filter-target='group']")
      hidden = groups.select { it.key?("data-hidden-by-done") }.map { it.at_css("h2").text.strip }

      expect(groups.size).to eq 5
      expect(hidden).to eq [ "6/23" ]
    end

    it "全件が完了済みで隠れたときの空状態を初期非表示で持つ" do
      empty = html.at_css("[data-completed-filter-target='empty']")

      expect(empty["hidden"]).not_to be_nil
      expect(empty.text).to include("表示できるタスクはありません", "完了済みを表示")
    end
  end

  describe "空状態（?empty=1）" do
    it "一覧の代わりに、まだタスクが無い旨とタスクを作るへの導線を表示する" do
      get "/tasks", params: { empty: "1" }

      expect(rows).to be_empty
      expect(html.css("section")).to be_empty
      empty = html.at_css("[data-my-tasks-empty]")
      expect(empty.text).to include("まだタスクがありません", "やりたいことを入力すると、AI が手順に分解します。")
      expect(empty.at_css("a")["href"]).to eq "/"
      expect(empty.at_css("a").text.strip).to eq "タスクを作る"
      expect(empty["hidden"]).to be_nil
    end

    it "ヘッダーと見出しは維持し、完了済みの空状態は出さない" do
      get "/tasks", params: { empty: "1" }

      expect(html.at_css("header").text).to include("マイタスク", "完了済みを表示")
      expect(html.at_css("h1").text.strip).to eq "マイタスク"
      expect(html.at_css("[data-completed-filter-target='empty']")).to be_nil
    end

    [ "0", "true", "", [ "1" ] ].each do |value|
      it "empty=#{value.inspect} は通常の一覧を表示する" do
        get "/tasks", params: { empty: value }

        expect(rows.size).to eq 6
        expect(html.at_css("[data-my-tasks-empty]")).to be_nil
      end
    end
  end
end
