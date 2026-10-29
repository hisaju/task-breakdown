FactoryBot.define do
  # User モデルのテストデータ生成テンプレート
  factory :user do
    name { "テストユーザー" }
    # 一意性エラーを防ぐため連番化
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    # 呼び出し時の現在時刻を設定
    terms_accepted_at { Time.current }
  end
end
