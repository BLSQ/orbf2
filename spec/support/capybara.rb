# frozen_string_literal: true

Capybara.register_driver :headless_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    # This enables access to logs with `page.driver.manage.get_log(:browser)`
    loggingPrefs: {
      browser: "ALL",
      client:  "ALL",
      driver:  "ALL",
      server:  "ALL"
    }
  )

  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("window-size=1400,1400")

  # Chrome won't work properly in a Docker container in sandbox mode
  #   because the user namespace is not enabled in the container by default
  options.add_argument("no-sandbox")

  # Run headless by default unless CHROME_HEADLESS specified
  options.add_argument("headless") unless ENV["CHROME_HEADLESS"] =~ /^(false|no|0)$/i

  # Disable /dev/shm use in CI. See https://gitlab.com/gitlab-org/gitlab-ee/issues/4252
  options.add_argument("disable-dev-shm-usage") if ENV["CI"] || ENV["CI_SERVER"]

  Capybara::Selenium::Driver.new(
    app,
    browser:              :chrome,
    desired_capabilities: capabilities,
    options:              options
  )
end
