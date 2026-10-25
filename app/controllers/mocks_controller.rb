# 画面モック用コントローラ。表示用の固定データのみを持ち、永続化や AI 分解は行わない。
class MocksController < ApplicationController
  EXAMPLES = %w[イベントの企画を進める 資格試験の学習計画を立てる 引っ越しの準備をする].freeze

  SAMPLE_SUBTASKS = [
    { kind: :basic, due: "今日", title: "目的と読み手を整理する", description: "誰に何を伝える資料か、ゴールを1文で定義する" },
    { kind: :basic, due: "今日", title: "必要な情報を集める", description: "過去資料・数値・関係者の意見をまとめる" },
    { kind: :special, due: "明日", title: "上長に方向性を確認する", description: "構成案を共有し、認識のずれがないか確認する" },
    { kind: :basic, due: "6/24", title: "初稿を作成する", description: "見出しに沿って本文と図表を作成する" }
  ].freeze

  DATE_TABS = %w[すべて 今日 明日 6/24].freeze

  # マイタスク（親タスク一覧）。日付見出しごとに期限の近い順
  SAMPLE_PARENT_TASKS = [
    { date: "今日", tasks: [
      { title: "経費申請", due: "今日 17:00", status: :decomposing, done: 0, total: 0 },
      { title: "見積もり作成", due: "今日 18:00", status: :done_decomposing, done: 1, total: 3 }
    ] },
    { date: "明日", tasks: [
      { title: "社内提案資料を作成する", due: "明日 12:00", status: :done_decomposing, done: 2, total: 4 }
    ] },
    { date: "6/24", tasks: [
      { title: "起案書作成", due: "6/24 17:00", status: :done_decomposing, done: 0, total: 6 }
    ] },
    { date: "期限なし", tasks: [
      { title: "引っ越しの準備をする", due: nil, status: :failed, done: 0, total: 0 }
    ] }
  ].freeze

  def new_task
  end

  def my_tasks
  end

  def signup
    render layout: "auth"
  end

  def login
    render layout: "auth"
  end

  def task_detail
    @title = params[:title].presence || "社内提案資料を作成する"
  end
end
