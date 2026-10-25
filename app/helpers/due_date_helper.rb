# 期限（日時）の表示を S-4 / S-5 で揃えるためのヘルパー。
# 「今日」「明日」の判定はアプリのタイムゾーン（Time.zone）の暦日で行う。
module DueDateHelper
  NO_DUE_LABEL = "期限なし".freeze

  # 期限の表示文字列。例:「今日 17:00」「明日 12:00」「6/27 17:00」「期限なし」
  # date_only: true では日付部分だけ（日付タブ・日付見出し用）
  def due_label(time, date_only: false)
    return NO_DUE_LABEL if time.nil?

    date = due_date_part(time)
    date_only ? date : "#{date} #{time.in_time_zone.strftime('%H:%M')}"
  end

  # 日付による絞り込み・グループ化に使うキー。today / tomorrow / YYYY-MM-DD / none
  def due_key(time)
    return "none" if time.nil?

    case time.in_time_zone.to_date
    when Date.current then "today"
    when Date.current.tomorrow then "tomorrow"
    else time.in_time_zone.to_date.iso8601
    end
  end

  # 期限を <time datetime="..."> で表示する。期限が無ければ「期限なし」
  def due_time_tag(time)
    return tag.span(NO_DUE_LABEL) if time.nil?

    tag.time(due_label(time), datetime: time.in_time_zone.iso8601)
  end

  private

  def due_date_part(time)
    date = time.in_time_zone.to_date
    case date
    when Date.current then "今日"
    when Date.current.tomorrow then "明日"
    else "#{date.month}/#{date.day}"
    end
  end
end
