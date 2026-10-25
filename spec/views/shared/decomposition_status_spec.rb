require "rails_helper"

RSpec.describe "shared/_decomposition_status" do
  def badge
    Nokogiri::HTML.fragment(rendered).at_css("[data-decomposition-status]")
  end

  {
    decomposing: [ "分解中", "text-accent", true ],
    done: [ "分解完了", "text-brand", false ],
    failed: [ "分解失敗", "text-danger", false ]
  }.each do |status, (label, color, pulse)|
    it "#{status} は「#{label}」を #{color} で表示する" do
      render partial: "shared/decomposition_status", locals: { status: }

      expect(badge["data-decomposition-status"]).to eq status.to_s
      expect(badge.text.strip).to eq label
      expect(badge["class"]).to include(color, "text-2xs")
      expect(badge.to_html.include?("animate-pulse")).to eq pulse
    end
  end

  it "未知の状態は受け付けない" do
    expect { render partial: "shared/decomposition_status", locals: { status: :unknown } }
      .to raise_error(ActionView::Template::Error, /unknown/)
  end
end
