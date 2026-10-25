require "rails_helper"

RSpec.describe "画面モック" do
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
end
