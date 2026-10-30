class Task < ApplicationRecord
  # 関連付け
  belongs_to :user
  belongs_to :parent, class_name: "Task", optional: true
  has_many :children, class_name: "Task", foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent

  # 列挙型（Enum）の定義 (Rails 7.1+ 記法)
  enum :kind, { basic: 0, special: 1 }
  enum :status, { todo: 0, done: 1 }
  enum :source, { manual: 0, ai: 1 }

  # バリデーション
  validates :title, presence: true, length: { maximum: 200 }
  validate :due_at_cannot_be_in_the_past, on: :create

  private

  # 期限は新規作成時に現在より前の日時を設定できない (docs/requirements.md UC-1)
  def due_at_cannot_be_in_the_past
    return if due_at.blank?

    if due_at < Time.current
      errors.add(:due_at, "は現在より前の日時を設定できません")
    end
  end
end