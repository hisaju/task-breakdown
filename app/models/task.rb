class Task < ApplicationRecord
  # 入力例チップ用の例文
  EXAMPLES = [
    "イベントの企画を進める",
    "資格試験の学習計画を立てる",
    "引っ越しの準備をする"
  ].freeze

  # 関連付け
  belongs_to :user
  belongs_to :parent, class_name: "Task", optional: true
  has_many :children, class_name: "Task", foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent

  # 列挙型（Enum）
  enum :kind, { basic: 0, special: 1 }
  enum :status, { todo: 0, done: 1 }
  enum :source, { manual: 0, ai: 1 }

  # バリデーション
  validates :title, presence: true, length: { maximum: 200 }
  validate :due_at_cannot_be_in_the_past, on: :create

  # スコープ
  # 親タスクのみ取得（parent_id が nil）
  scope :roots, -> { where(parent_id: nil) }

  # 期限の近い順（未設定は末尾）
  scope :ordered_by_due, -> { order(Arel.sql("due_at ASC NULLS LAST"), :id) }

  # サブタスクの進捗（完了数/全体数）を返す（サブタスクがない場合は nil）
  def progress
    total = children.size
    return nil if total.zero?

    completed = children.count(&:done?)
    { completed: completed, total: total }
  end

  private

  # 期限は新規作成時に過去日時を指定不可（UC-1）
  def due_at_cannot_be_in_the_past
    return if due_at.blank?

    if due_at < Time.current
      errors.add(:due_at, :cannot_be_in_the_past)
    end
  end
end
