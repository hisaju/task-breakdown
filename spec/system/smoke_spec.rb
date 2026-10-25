require "rails_helper"

# JavaScript（Stimulus）を動かす system spec の基盤が、ローカルと CI の両方で動くことを確かめる
RSpec.describe "JS system spec の基盤", :js do
  it "入力例チップを押すと入力欄に例文が入る" do
    visit root_path

    textarea = find("textarea[aria-label='取り組みたいこと']")
    expect(textarea.value).to eq ""

    click_on "資格試験の学習計画を立てる"

    expect(textarea.value).to eq "資格試験の学習計画を立てる"
    expect(page).to have_css("textarea:focus")
  end
end
