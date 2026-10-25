require "capybara/cuprite"

Capybara.register_driver(:cuprite_ja) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [ 1280, 900 ],
    browser_options: { "no-sandbox" => nil, "lang" => "ja-JP" },
    headless: ENV.fetch("HEADLESS", "true") != "false",
    process_timeout: 20,
    # Web フォントは読み込まない。外部への応答待ちでページの読み込みが終わらず、Ferrum がタイムアウトするのを防ぐ
    url_blacklist: [ %r{\Ahttps://fonts\.(googleapis|gstatic)\.com/} ]
  )
end

Capybara.default_max_wait_time = 5
Capybara.enable_aria_label = true

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, :js, type: :system) do
    driven_by :cuprite_ja
  end
end
