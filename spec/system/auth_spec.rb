require "rails_helper"

RSpec.describe "S-1 ログイン・S-2 会員登録", :js do
  def fill_signup(except: nil)
    {
      "お名前" => "山田 優", "メールアドレス" => "yu.yamada@example.com",
      "パスワード" => "password123", "パスワード（確認）" => "password123"
    }.except(except).each { |label, value| fill_in label, with: value }
  end

  describe "S-2 会員登録" do
    before { visit "/signup" }

    it "同意にチェックしないと送信されない" do
      fill_signup
      click_on "アカウントを作成する"

      sleep 0.3
      expect(page).to have_current_path("/signup")
      expect(page.evaluate_script("document.querySelector('input[name=terms]').validity.valueMissing")).to be true
    end

    it "パスワードが 8 文字未満だと送信されない" do
      fill_signup
      # minlength はユーザーが入力した値にだけ効くので、キー入力で打ち込む
      find_field("パスワード").fill_in(with: "")
      find_field("パスワード").send_keys("pass123")
      check "利用規約とプライバシーポリシーに同意する"
      click_on "アカウントを作成する"

      sleep 0.3
      expect(page).to have_current_path("/signup")
      expect(page.evaluate_script("document.querySelector('input[name=password]').validity.tooShort")).to be true
    end

    it "未入力の項目があると送信されない" do
      fill_signup(except: "お名前")
      check "利用規約とプライバシーポリシーに同意する"
      click_on "アカウントを作成する"

      sleep 0.3
      expect(page).to have_current_path("/signup")
    end

    it "すべて入力して同意すると、URL に入力値を残さずホームへ移る" do
      fill_signup
      check "利用規約とプライバシーポリシーに同意する"
      click_on "アカウントを作成する"

      expect(page).to have_css("h1", text: "今日は何に取り組みますか？")
      expect(page).to have_current_path("/", ignore_query: false)
    end

    it "利用規約を新しいタブで開いても、入力途中のフォームはそのまま残る" do
      fill_in "お名前", with: "山田 優"
      terms = window_opened_by { click_on "利用規約" }

      within_window(terms) do
        expect(page).to have_css("h1", text: "利用規約")
        expect(page).to have_link("会員登録に戻る", href: "/signup")
      end
      expect(page).to have_current_path("/signup")
      expect(find_field("お名前").value).to eq "山田 優"
    end
  end

  describe "S-1 ログイン" do
    before { visit "/login" }

    it "未入力では送信されない" do
      fill_in "メールアドレス", with: "yu.yamada@example.com"
      click_on "ログイン"

      sleep 0.3
      expect(page).to have_current_path("/login")
    end

    it "入力して送信すると、URL にパスワードを残さずホームへ移る" do
      fill_in "メールアドレス", with: "yu.yamada@example.com"
      fill_in "パスワード", with: "password123"
      click_on "ログイン"

      expect(page).to have_css("h1", text: "今日は何に取り組みますか？")
      expect(page).to have_current_path("/", ignore_query: false)
    end
  end
end
