require "rails_helper"

RSpec.describe "S-4 タスク詳細（画面モック）" do
  before do
    travel_to(Time.zone.local(2026, 6, 20, 10, 0))
  end

  def html
    Nokogiri::HTML(response.body)
  end

  # <template> の中身は除く（Nokogiri は template の子も通常の要素として読む）
  def cards
    html.css("ol[data-subtasks-target='list'] > li")
  end

  def status
    html.at_css("[data-decomposition-status]")["data-decomposition-status"]
  end

  def progress
    html.at_css("[data-task-progress]")
  end

  describe "分解ステータスの 3 状態" do
    it "指定が無ければ分解完了で、日付タブとサブタスクを表示する" do
      get "/tasks/sample"

      expect(status).to eq "done"
      expect(response.body).to include("AI が実行しやすい手順に分解しました。内容は自由に編集できます。")
      expect(html.at_css("[role='tablist']")).to be_present
      expect(cards.size).to eq 6
      expect(html.css("[data-skeleton]")).to be_empty
    end

    it "不正な値は分解完了として扱う" do
      get "/tasks/sample", params: { status: "unknown" }

      expect(status).to eq "done"
      expect(cards.size).to eq 6
    end

    it "分解中はタブと一覧の代わりにスケルトン 3 枚を出し、「タスクを追加」は残す" do
      get "/tasks/sample", params: { status: "decomposing" }

      expect(status).to eq "decomposing"
      expect(response.body).to include("AI が実行しやすい手順に分解しています。通常 30 秒以内に完了します。")
      expect(html.css("[data-skeleton] > *").size).to eq 3
      expect(html.at_css("[data-skeleton]")["aria-hidden"]).to eq "true"
      expect(html.at_css("[role='tablist']")).to be_nil
      expect(cards).to be_empty
      expect(html.at_css("button[data-action='subtasks#add']").text).to include("タスクを追加")
      expect(response.body).not_to include("再分解する")
    end

    it "分解失敗は案内と「再分解する」（見た目のみ）を出し、一覧は空で「タスクを追加」は残す" do
      get "/tasks/sample", params: { status: "failed" }

      expect(status).to eq "failed"
      expect(response.body).to include("分解に失敗しました。再度お試しください")
      retry_button = html.css("button").find { it.text.strip == "再分解する" }
      expect(retry_button["type"]).to eq "button"
      expect(retry_button["data-mock"]).to eq "noop"
      expect(html.at_css("[role='tablist']")).to be_nil
      expect(html.css("[data-skeleton]")).to be_empty
      expect(cards).to be_empty
      expect(html.at_css("button[data-action='subtasks#add']")).to be_present
    end
  end

  describe "タイトル（?title=）" do
    it "文字列以外（配列・ハッシュ）はサンプルの親タスク名にする" do
      [ "title[]=a", "title[k]=v" ].each do |query|
        get "/tasks/sample?#{query}"

        expect(html.at_css("h1").text.strip).to eq("社内提案資料を作成する"), query
      end
    end
  end

  describe "分解中からの自動遷移" do
    it "分解中は 3 秒後に分解完了の URL（タイトル・期限を引き継ぐ）へ遷移する設定を持つ" do
      get "/tasks/sample", params: { status: "decomposing", title: "経費申請", due: "2026-06-21T15:00" }

      root = html.at_css("[data-controller~='decomposition-progress']")
      expect(root["data-decomposition-progress-delay-value"]).to eq "3000"
      expect(root["data-decomposition-progress-autoplay-value"]).to eq "true"
      url = URI.parse(root["data-decomposition-progress-url-value"])
      expect(url.path).to eq "/tasks/sample"
      expect(Rack::Utils.parse_query(url.query)).to eq(
        "status" => "done", "title" => "経費申請", "due" => "2026-06-21T15:00"
      )
    end

    it "文字列でない title は遷移先に引き継がない" do
      get "/tasks/sample?status=decomposing&title[]=a&due=2026-06-21T15:00"

      url = URI.parse(html.at_css("[data-controller~='decomposition-progress']")["data-decomposition-progress-url-value"])
      expect(Rack::Utils.parse_query(url.query)).to eq("status" => "done", "due" => "2026-06-21T15:00")
    end

    it "autoplay=0 では遷移しない設定になる" do
      get "/tasks/sample", params: { status: "decomposing", autoplay: "0" }

      root = html.at_css("[data-controller~='decomposition-progress']")
      expect(root["data-decomposition-progress-autoplay-value"]).to eq "false"
    end

    it "分解完了・分解失敗では自動遷移しない" do
      %w[done failed].each do |value|
        get "/tasks/sample", params: { status: value }

        expect(html.at_css("[data-controller~='decomposition-progress']")).to be_nil
      end
    end
  end

  describe "親タスクの期限と進捗" do
    def parent_due
      html.at_css("[data-parent-due]").text.squish
    end

    it "期限の指定が無ければサンプルの期限（S-5 と同じ）を表示する" do
      get "/tasks/sample"

      expect(parent_due).to eq "6/27 17:00"
      expect(html.at_css("[data-parent-due] time")["datetime"]).to eq "2026-06-27T17:00:00+09:00"
    end

    it "有効な日時を指定するとその期限を表示する" do
      get "/tasks/sample", params: { due: "2026-06-21T15:00" }

      expect(parent_due).to eq "明日 15:00"
    end

    it "不正な値・空の値は「期限なし」" do
      [ "abc", "2026-13-45T10:00", "" ].each do |value|
        get "/tasks/sample", params: { due: value }

        expect(parent_due).to eq("期限なし"), "due=#{value.inspect}"
      end
    end

    it "分解完了は進捗を n/m 完了で表示し、progressbar として値を持つ" do
      get "/tasks/sample"

      expect(progress.text.squish).to eq "1/6 完了"
      expect(progress["role"]).to eq "progressbar"
      expect(progress.attributes.slice("aria-valuemin", "aria-valuenow", "aria-valuemax").transform_values(&:value))
        .to eq("aria-valuemin" => "0", "aria-valuenow" => "1", "aria-valuemax" => "6")
      expect(progress["aria-label"]).to eq "進捗"
    end

    it "分解中・分解失敗は進捗「—」" do
      %w[decomposing failed].each do |value|
        get "/tasks/sample", params: { status: value }

        expect(progress.text.squish).to eq "—"
        expect(progress["role"]).to be_nil
      end
    end
  end

  describe "メニュー" do
    it "親タスクのメニューは編集・再分解・削除（見た目のみ）で、削除は赤字" do
      get "/tasks/sample"

      trigger = html.at_css("#task-menu").parent.at_css("button[aria-haspopup='menu']")
      expect(trigger["aria-controls"]).to eq "task-menu"
      expect(trigger["aria-label"]).to eq "「社内提案資料を作成する」のメニュー"
      items = html.css("#task-menu [role='menuitem']")
      expect(items.map { it.text.strip }).to eq %w[編集 再分解 削除]
      expect(items.map { it["data-mock"] }).to all(eq "noop")
      expect(items.last["class"]).to include("text-danger")
    end

    it "サブタスクのメニューは編集・期限設定・削除で、id は番号から一意に作る" do
      get "/tasks/sample"

      cards.each.with_index(1) do |card, number|
        id = format("subtask-menu-%02d", number)
        title = card.at_css("[data-subtask-card-target='title']").text.strip
        trigger = card.at_css("button[aria-haspopup='menu']")
        expect(trigger["aria-controls"]).to eq id
        expect(trigger["aria-label"]).to eq "「#{title}」のメニュー"
        items = card.css("##{id} [role='menuitem']")
        expect(items.map { it.text.strip }).to eq %w[編集 期限設定 削除]
        expect(items.map { it["data-mock"] }).to all(eq "noop")
      end
      ids = html.css("[id]").map { it["id"] }
      expect(ids).to eq ids.uniq
    end

    it "追加用テンプレートは番号の置き場所を __NUMBER__ にしたメニューを持つ" do
      get "/tasks/sample"

      template = html.at_css("template[data-subtasks-target='template']")
      expect(template.inner_html).to include('id="subtask-menu-__NUMBER__"', 'aria-controls="subtask-menu-__NUMBER__"')
      expect(template.inner_html).to include("編集", "期限設定", "削除")
    end
  end

  describe "種別バッジ" do
    it "基本タスク・特殊タスクの意味を title で示す" do
      get "/tasks/sample"

      badges = cards.css("[data-kind-badge]").to_h { [ it.text.strip, it["title"] ] }
      expect(badges).to eq(
        "基本タスク" => "自分だけで進められる手順",
        "特殊タスク" => "他者の確認・承認・返答待ちが発生する手順。早めに着手する"
      )
    end
  end

  describe "完了チェック" do
    def check_labels
      cards.map { it.at_css("button[data-action~='subtask-card#toggle']")["aria-label"] }
    end

    it "初期描画で data-done と aria-label・番号が一致する（完了済みは「未完了に戻す」）" do
      get "/tasks/sample"

      expect(cards.map { it["data-done"] }).to eq %w[true false false false false false]
      expect(check_labels.first).to eq "「依頼の背景と締め切りを確認する」を未完了に戻す"
      expect(check_labels.drop(1)).to all(end_with("」を完了にする"))
      expect(cards.map { it.at_css("[data-subtask-number]").text.strip }).to eq %w[01 02 03 04 05 06]
    end

    it "全完了の空状態は初期非表示で、文言と導線を持つ" do
      get "/tasks/sample"

      empty = html.at_css("[data-completed-filter-target='empty']")
      expect(empty["hidden"]).not_to be_nil
      expect(empty.text).to include("すべての手順が完了しました", "「完了済みを表示」")
      expect(empty.at_css("a")["href"]).to eq "/tasks"
      expect(empty.at_css("a").text.strip).to eq "マイタスクへ"
    end

    it "all_done=1 では全サブタスクを完了済みにし、全完了の空状態と 6/6 完了を最初から表示する" do
      get "/tasks/sample", params: { status: "done", all_done: "1" }

      expect(cards.map { it["data-done"] }).to all(eq "true")
      expect(cards.map { it.key?("data-hidden-by-done") }).to all(be true)
      expect(html.at_css("[data-completed-filter-target='empty']")["hidden"]).to be_nil
      expect(progress.text.squish).to eq "6/6 完了"
      expect(check_labels).to all(end_with("」を未完了に戻す"))
    end
  end

  describe "日付タブ" do
    def tabs
      html.css("[role='tablist'] [role='tab']")
    end

    it "すべて・日付ごとのタブを持ち、最初は「すべて」が選ばれている" do
      get "/tasks/sample"

      tablist = html.at_css("[role='tablist']")
      expect(tablist["aria-label"]).to eq "期限の日付で絞り込む"
      expect(tablist["data-controller"]).to be_nil
      expect(tabs.map { it.text.strip }).to eq %w[すべて 今日 明日 6/27]
      expect(tabs.map { it["data-due-key"] }).to eq %w[all today tomorrow 2026-06-27]
      expect(tabs.map { it["aria-selected"] }).to eq %w[true false false false]
      # 選択中のタブだけが Tab キーで止まる（タブ間は ←→ で移る）
      expect(tabs.map { it["tabindex"] }).to eq %w[0 -1 -1 -1]
      expect(tabs.map { it["data-action"] }).to all(include("date-tabs#select"))
    end

    it "タブは一覧（tabpanel）を aria-controls で指し、tabpanel は選択中のタブを aria-labelledby で指す" do
      get "/tasks/sample"

      expect(tabs.map { it["aria-controls"] }.uniq).to eq [ "subtask-panel" ]
      panel = html.at_css("#subtask-panel")
      expect(panel["role"]).to eq "tabpanel"
      expect(panel["aria-labelledby"]).to eq tabs.first["id"]
      expect(tabs.map { it["id"] }).to eq %w[date-tab-all date-tab-today date-tab-tomorrow date-tab-2026-06-27]
      expect(panel.at_css("ol[data-subtasks-target='list']")).to be_present
    end

    it "初期表示でどのカードも日付タブで隠さない" do
      get "/tasks/sample"

      expect(cards.map { it.key?("data-hidden-by-tab") }).to all(be false)
      expect(cards.map { it["data-due-key"] }).to eq %w[today today today tomorrow 2026-06-27 none]
    end

    it "タブで 0 件になったときの空状態を、全完了の空状態とは別の要素として持つ（初期非表示）" do
      get "/tasks/sample"

      empty = html.at_css("[data-date-tabs-target='empty']")
      expect(empty["hidden"]).not_to be_nil
      expect(empty.text).to include("この日のサブタスクはありません")
      expect(empty["data-completed-filter-target"]).to be_nil
      expect(empty.text).not_to include("すべての手順が完了しました")
    end

    it "分解中・分解失敗では日付タブの絞り込みを持たない" do
      %w[decomposing failed].each do |value|
        get "/tasks/sample", params: { status: value }

        expect(html.at_css("[data-controller~='date-tabs']")).to be_nil
        expect(html.at_css("[data-date-tabs-target='empty']")).to be_nil
        expect(html.at_css("[role='tabpanel']")).to be_nil
      end
    end
  end

  describe "追加カード" do
    def template_card
      Nokogiri::HTML::DocumentFragment.parse(html.at_css("template[data-subtasks-target='template']").inner_html).at_css("li")
    end

    it "追加カードのタスク名・補足は入力欄（contenteditable）で、プレースホルダと aria-label を持つ" do
      get "/tasks/sample"

      title = template_card.at_css("[data-subtask-card-target='title']")
      expect(title["contenteditable"]).to eq "true"
      expect(title["role"]).to eq "textbox"
      expect(title["aria-label"]).to eq "タスク名"
      expect(title["aria-placeholder"]).to eq "タスク名を入力"
      expect(title["data-placeholder"]).to eq "タスク名を入力"
      expect(title.text).to eq ""

      description = template_card.at_css("[data-subtask-card-target='description']")
      expect(description["contenteditable"]).to eq "true"
      expect(description["role"]).to eq "textbox"
      expect(description["aria-multiline"]).to eq "true"
      expect(description["aria-label"]).to eq "補足"
      expect(description["aria-placeholder"]).to eq "補足を入力（任意）"
      expect(description["data-placeholder"]).to eq "補足を入力（任意）"
      expect(description.text).to eq ""
    end

    it "追加カードは期限が今日で、入力前の完了チェック・メニューは「新しいタスク」と読み上げる" do
      get "/tasks/sample"

      expect(template_card["data-due-key"]).to eq "today"
      expect(template_card.at_css("[data-subtask-card-target='check']")["aria-label"]).to eq "「新しいタスク」を完了にする"
      expect(template_card.at_css("button[aria-haspopup='menu']")["aria-label"]).to eq "「新しいタスク」のメニュー"
      expect(template_card["data-subtask-card-title-value"]).to eq ""
      expect(template_card["data-subtask-card-default-title-value"]).to eq "新しいタスク"
    end

    it "既存のカードは編集できない" do
      get "/tasks/sample"

      expect(cards.css("[contenteditable]")).to be_empty
    end
  end
end
