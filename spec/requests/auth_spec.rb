require "rails_helper"

RSpec.describe "S-1 ログイン・S-2 会員登録・規約ページ（画面モック）" do
  def html
    Nokogiri::HTML(response.body)
  end

  def form
    html.at_css("main form")
  end

  def field(name)
    form.at_css("input[name='#{name}']")
  end

  describe "S-1 ログイン" do
    before { get "/login" }

    it "POST で /login へ送る" do
      expect(form["action"]).to eq "/login"
      expect(form["method"]).to eq "post"
    end

    it "メールアドレスとパスワードは必須" do
      expect(field("email")["type"]).to eq "email"
      expect(field("password")["type"]).to eq "password"
      expect(field("password")["autocomplete"]).to eq "current-password"
      expect([ field("email"), field("password") ]).to all(have_attribute("required"))
      expect(field("remember_me")).not_to have_attribute("required")
    end

    it "入力欄はすべてラベルと結び付いている" do
      form.css("input[type='email'], input[type='password']").each do |input|
        expect(html.at_css("label[for='#{input['id']}']")).to be_present
      end
    end

    it "パスワード再設定のリンクと href=# を持たない" do
      expect(response.body).not_to include("パスワードをお忘れですか？")
      expect(html.css("a[href='#']")).to be_empty
    end
  end

  describe "S-2 会員登録" do
    before { get "/signup" }

    it "POST で /signup へ送る" do
      expect(form["action"]).to eq "/signup"
      expect(form["method"]).to eq "post"
    end

    it "全入力と同意チェックは必須で、パスワードは 8 文字以上" do
      inputs = %w[name email password password_confirmation].map { field(it) }
      expect(inputs).to all(have_attribute("required"))
      expect(field("password")["minlength"]).to eq "8"
      expect(field("terms")["type"]).to eq "checkbox"
      expect(field("terms")).to have_attribute("required")
    end

    it "パスワードの補足（8文字以上）を入力欄の説明として読み上げる" do
      hint = html.at_css("##{field('password')['aria-describedby']}")
      expect(hint.text.strip).to eq "8文字以上で入力してください"
    end

    it "同意文から利用規約・プライバシーポリシーへリンクし、href=# を持たない" do
      consent = field("terms").ancestors("label").first
      links = consent.css("a").to_h { [ it.text.strip, it["href"] ] }

      expect(links).to eq("利用規約" => "/terms", "プライバシーポリシー" => "/privacy")
      # 入力途中のフォームを失わないよう新しいタブで開く
      expect(consent.css("a").map { [ it["target"], it["rel"] ] }).to all(eq %w[_blank noopener])
      expect(html.css("a[href='#']")).to be_empty
    end

    it "規約リンクが新しいタブで開くことを同意文の下に表示し、各リンクの説明として読み上げる" do
      consent = field("terms").ancestors("label").first
      notes = consent.css("a").map { html.at_css("##{it['aria-describedby']}")&.text&.strip }

      expect(notes).to eq [ "（いずれも新しいタブで開きます）" ] * 2
    end
  end

  describe "送信（保存・検証なし）" do
    it "POST /login はホームへリダイレクトし、入力値を URL に残さない" do
      post "/login", params: { email: "yu.yamada@example.com", password: "password123" }

      expect(response).to have_http_status(:found)
      expect(response.location).to eq "http://www.example.com/"
    end

    it "POST /signup はホームへリダイレクトし、入力値を URL に残さない" do
      post "/signup", params: { name: "山田 優", email: "yu.yamada@example.com",
                                password: "password123", password_confirmation: "password123", terms: "1" }

      expect(response).to have_http_status(:found)
      expect(response.location).to eq "http://www.example.com/"
    end
  end

  {
    "/terms" => { title: "利用規約", eyebrow: "TERMS OF SERVICE" },
    "/privacy" => { title: "プライバシーポリシー", eyebrow: "PRIVACY POLICY" }
  }.each do |path, page|
    describe path do
      before { get path }

      it "ログイン前の画面として見出し・本文・会員登録への戻り先を表示する" do
        expect(response).to have_http_status(:ok)
        expect(html.at_css("head title").text).to eq "#{page[:title]} | Tasklet"
        expect(html.at_css("h1").text.strip).to eq page[:title]
        expect(html.text).to include(page[:eyebrow])
        expect(html.at_css("aside")).to be_nil
        expect(html.css("article p").size).to be_between(2, 3)
        expect(html.at_css("a[href='/signup']").text.strip).to eq "会員登録に戻る"
        expect(html.css("a[href='#']")).to be_empty
      end
    end
  end
end
