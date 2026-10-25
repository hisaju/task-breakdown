require "rails_helper"

RSpec.describe "画面モック" do
  # 「今日 17:00」「明日 12:00」「6/27 17:00」の書式（時刻付き）
  let(:due_format) { %r{\A(今日|明日|\d{1,2}/\d{1,2}) \d{2}:\d{2}\z} }

  def html
    Nokogiri::HTML(response.body)
  end

  {
    "/" => "今日は何に取り組みますか？",
    "/tasks" => "起案書作成",
    "/tasks/sample" => "社内提案資料を作成する",
    "/signup" => "アカウントを作成する",
    "/login" => "おかえりなさい"
  }.each do |path, text|
    it "#{path} が表示できる" do
      get path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(text)
    end
  end

  it "入力した内容をタスク詳細の見出しに表示する" do
    get "/tasks/sample", params: { title: "経費申請" }

    expect(response.body).to include("経費申請")
  end

  describe "共通 head" do
    it "画面ごとのタイトルを表示する" do
      get "/login"

      expect(html.at_css("head title").text).to eq "ログイン | Tasklet"
    end

    it "両レイアウトで同じ head 要素を持つ" do
      heads = %w[/ /login].map do |path|
        get path
        html.css("head meta[name], head link[rel='icon']").map(&:to_html)
      end

      expect(heads.first).to eq heads.last
      expect(heads.first).not_to be_empty
    end
  end

  describe "サイドバーの現在地" do
    { "/" => "タスクを作る", "/tasks" => "マイタスク" }.each do |path, label|
      it "#{path} では「#{label}」だけが aria-current=page" do
        get path

        current = html.css("aside [aria-current='page']")
        expect(current.size).to eq 1
        expect(current.first.text.strip).to eq label
      end
    end
  end

  describe "サンプルデータの日付" do
    it "表示日に応じて期限の表示が変わる（固定値ではない）" do
      travel_to(Time.zone.local(2026, 6, 20, 10, 0)) { get "/tasks/sample" }
      first_tabs = html.css("[role='tab']").map { it.text.strip }
      expect(first_tabs).to eq %w[すべて 今日 明日 6/27]
      expect(response.body).to include("6/27 17:00")

      travel_to(Time.zone.local(2026, 7, 1, 10, 0)) { get "/tasks/sample" }
      expect(html.css("[role='tab']").map { it.text.strip }).to eq %w[すべて 今日 明日 7/8]
      expect(response.body).to include("7/8 17:00")
      expect(response.body).not_to include("6/27")
    end

    it "マイタスクの日付見出しは表示日から導出される" do
      travel_to(Time.zone.local(2026, 6, 20, 10, 0)) { get "/tasks" }
      expect(html.css("section h2").map { it.text.strip }).to eq %w[今日 明日 6/27 期限なし]

      travel_to(Time.zone.local(2026, 12, 31, 10, 0)) { get "/tasks" }
      expect(html.css("section h2").map { it.text.strip }).to eq %w[今日 明日 1/7 期限なし]
    end
  end

  describe "S-4 と S-5 の整合" do
    before do
      travel_to(Time.zone.local(2026, 6, 20, 10, 0))
    end

    it "S-5「社内提案資料を作成する」の n/m 完了が S-4 サンプルの完了数／件数と一致する" do
      get "/tasks/sample"
      cards = html.css("ol[data-subtasks-target='list'] > li")
      done = cards.count { it["data-done"] == "true" }
      expect(cards.size).to eq 6
      expect(done).to eq 1

      get "/tasks"
      row = html.css("a").find { it.text.include?("社内提案資料を作成する") }
      expect(row.text).to include("#{done}/#{cards.size} 完了")
    end

    it "両画面の期限が同じ時刻付き書式で表示される" do
      labels = %w[/tasks/sample /tasks].map do |path|
        get path
        html.css("time[datetime]").map { it.text.strip }
      end

      labels.each do |list|
        expect(list).not_to be_empty
        expect(list).to all(match(due_format))
      end
      # 同じ日時は両画面で同じ文字列になる
      expect(labels.first & labels.last).to include("明日 12:00", "6/27 17:00")
    end

    it "期限なしのサンプルがサブタスクの末尾と親タスクの末尾にある" do
      get "/tasks/sample"
      last_card = html.css("ol[data-subtasks-target='list'] > li").last
      expect(last_card.text).to include("期限なし")
      expect(last_card.at_css("time")).to be_nil

      get "/tasks"
      expect(html.css("section").last.text).to include("引っ越しの準備をする")
    end

    it "親行は全完了のときだけ data-done=true を持ち、期限の data-due-key を持つ" do
      get "/tasks"

      rows = html.css("section li")
      done_titles = rows.select { it["data-done"] == "true" }.map { it.at_css("a p.font-serif").text.strip }
      expect(done_titles).to eq [ "経費精算の締め確認" ]
      expect(rows.map { it["data-done"] }).to all(be_in(%w[true false]))
      expect(rows.map { it["data-due-key"] }.uniq).to eq %w[today tomorrow 2026-06-27 none]
    end

    it "全完了の親タスク「経費精算の締め確認」を 3/3 完了で表示する" do
      get "/tasks"

      row = html.css("a").find { it.text.include?("経費精算の締め確認") }
      expect(row.text).to include("3/3 完了", "分解完了")
    end
  end
end
