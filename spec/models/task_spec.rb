require "rails_helper"

RSpec.describe Task do
  # ----------------------------------------------------------------
  # 1. バリデーション（保存ルール）のテスト
  # ----------------------------------------------------------------
  describe "バリデーション" do
    let(:user) { create(:user) }

    it "有効な属性を持つ場合は保存できること" do
      # 正常系：すべての値が正しければ問題なく保存できる
      task = build(:task, user: user)
      expect(task).to be_valid
    end

    # タスク名の文字数・空欄チェック（AC-2）
    describe "title" do
      it "空欄の場合は無効であること (AC-2)" do
        # タイトルが空っぽ（""）だと保存できずにエラーになる
        task = build(:task, user: user, title: "")
        expect(task).not_to be_valid
        expect(task.errors[:title]).to be_present
      end

      it "200文字の場合は有効であること" do
        # ちょうど上限の200文字なら合格
        task = build(:task, user: user, title: "a" * 200)
        expect(task).to be_valid
      end

      it "201文字以上の場合は無効であること (AC-2)" do
        # 201文字以上になると保存できずにエラーになる
        task = build(:task, user: user, title: "a" * 201)
        expect(task).not_to be_valid
        expect(task.errors[:title]).to be_present
      end
    end

    # 締め切り日時の過去日チェック（AC-3）
    describe "due_at" do
      it "過去の日時の場合は無効であること (AC-3)" do
        # 1分前（過去の日時）を指定した場合はエラーメッセージ付きで弾かれる
        task = build(:task, user: user, due_at: 1.minute.ago)
        expect(task).not_to be_valid
        expect(task.errors[:due_at]).to include("は現在より前の日時を設定できません")
      end

      it "未来の日時の場合は有効であること" do
        # 1時間後（未来の日時）なら合格
        task = build(:task, user: user, due_at: 1.hour.from_now)
        expect(task).to be_valid
      end

      it "期限が未設定（nil）の場合も有効であること" do
        # 「期限なし」のタスクも作れる仕様のため、空っぽ（nil）でも合格
        task = build(:task, user: user, due_at: nil)
        expect(task).to be_valid
      end
    end

    # ユーザーとの紐付けチェック（AC-4 / 認可の基盤）
    describe "user" do
      it "ユーザーに紐付いていない場合は無効であること (AC-4)" do
        # 持ち主（user_id）が存在しない迷子タスクは作成できない
        task = build(:task, user: nil)
        expect(task).not_to be_valid
        expect(task.errors[:user]).to be_present
      end
    end
  end

  # ----------------------------------------------------------------
  # 2. アソシエーション（関連付け）のテスト
  # ----------------------------------------------------------------
  describe "アソシエーション" do
    let(:user) { create(:user) }

    it "自己参照で親タスクと子タスク（サブタスク）の関連を持てること" do
      # 親タスクから子どもたち（children）が見え、子タスクから親（parent）が見えること
      parent_task = create(:task, user: user)
      child_task = create(:task, user: user, parent: parent_task)

      expect(child_task.parent).to eq(parent_task)
      expect(parent_task.children).to include(child_task)
    end

    it "親タスクが削除されたら子タスクも一緒に削除されること" do
      # 親タスクを削除した際、連動してサブタスクもデータベースから削除される（dependent: :destroy）
      parent_task = create(:task, user: user)
      create(:task, user: user, parent: parent_task)

      expect { parent_task.destroy }.to change(described_class, :count).by(-2)
    end
  end

  # ----------------------------------------------------------------
  # 3. 初期値（Enum・デフォルト値）のテスト
  # ----------------------------------------------------------------
  describe "初期値（Enum）" do
    let(:task) { build(:task) }

    it "デフォルトで basic / todo / manual であること" do
      # タスク作成直後は「基本タスク」「未完了」「手動作成」になっている
      expect(task).to be_basic
      expect(task).to be_todo
      expect(task).to be_manual
    end
  end
end
