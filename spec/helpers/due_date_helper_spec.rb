require "rails_helper"

RSpec.describe DueDateHelper do
  before do
    travel_to(Time.zone.local(2026, 6, 20, 10, 0))
  end

  describe "#due_label" do
    it "期限が無いときは「期限なし」" do
      expect(helper.due_label(nil)).to eq "期限なし"
    end

    it "当日は「今日 HH:MM」" do
      expect(helper.due_label(Time.zone.local(2026, 6, 20, 17, 0))).to eq "今日 17:00"
    end

    it "翌日は「明日 HH:MM」" do
      expect(helper.due_label(Time.zone.local(2026, 6, 21, 9, 5))).to eq "明日 09:05"
    end

    it "それ以外の日は「M/D HH:MM」" do
      expect(helper.due_label(Time.zone.local(2026, 6, 27, 17, 0))).to eq "6/27 17:00"
    end

    it "過去の日も「M/D HH:MM」" do
      expect(helper.due_label(Time.zone.local(2026, 6, 19, 23, 30))).to eq "6/19 23:30"
    end

    it "date_only: true では日付部分だけを返す" do
      expect(helper.due_label(Time.zone.local(2026, 6, 20, 17, 0), date_only: true)).to eq "今日"
      expect(helper.due_label(Time.zone.local(2026, 6, 21, 12, 0), date_only: true)).to eq "明日"
      expect(helper.due_label(Time.zone.local(2026, 6, 27, 17, 0), date_only: true)).to eq "6/27"
      expect(helper.due_label(nil, date_only: true)).to eq "期限なし"
    end
  end

  describe "#due_key" do
    it "期限が無いときは none" do
      expect(helper.due_key(nil)).to eq "none"
    end

    it "当日は today" do
      expect(helper.due_key(Time.zone.local(2026, 6, 20, 23, 59))).to eq "today"
    end

    it "翌日は tomorrow" do
      expect(helper.due_key(Time.zone.local(2026, 6, 21, 0, 0))).to eq "tomorrow"
    end

    it "それ以外の日は YYYY-MM-DD" do
      expect(helper.due_key(Time.zone.local(2026, 6, 27, 17, 0))).to eq "2026-06-27"
    end

    it "年をまたぐ日も YYYY-MM-DD" do
      expect(helper.due_key(Time.zone.local(2027, 1, 3, 9, 0))).to eq "2027-01-03"
    end
  end

  describe "#due_time_tag" do
    it "期限があれば datetime 付きの time 要素で表示する" do
      html = helper.due_time_tag(Time.zone.local(2026, 6, 20, 17, 0))

      expect(html).to include('<time datetime="2026-06-20T17:00:00+09:00">今日 17:00</time>')
    end

    it "期限が無ければ「期限なし」を表示する" do
      expect(helper.due_time_tag(nil)).to include("期限なし")
      expect(helper.due_time_tag(nil)).not_to include("<time")
    end
  end
end
