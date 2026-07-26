require_relative 'hash_helper'
require_relative 'credentials_helper'
require_relative 'driver_helper'

Dir[File.join(__dir__, '*.rb')].each { |f| require_relative f unless f == __FILE__ }

module Helper
  include HashHelper
  include CredentialsHelper
  include DriverHelper

  def set_input(element, value)
    element.click
    element.set(value)
  end

  def wait_page_full_load
    # Sobrescreva este método no projeto consumidor caso precise aguardar
    # algum indicador específico de carregamento da aplicação.
    sleep 0.5
  end

  def wait_for_loader(timeout: Capybara.default_max_wait_time)
    Capybara.using_wait_time(timeout) do
      expect(page).to have_no_css('.loader', wait: timeout)
    end
  rescue Capybara::ElementNotFound, RSpec::Expectations::ExpectationNotMetError
    nil
  end

  def wait_until_url_changes(old_url, wait_time = Capybara.default_max_wait_time)
    Capybara.using_wait_time(wait_time) do
      loop do
        break if page.current_url != old_url

        sleep 0.1
      end
    end
  end

  def start_resolution(x:, y:)
    @session = Capybara.current_session
    @browser = @session.driver.browser
    @browser.manage.window.resize_to(x, y)
  end

  def start_maximized
    @session = Capybara.current_session
    @browser = @session.driver.browser
    @browser.manage.window.maximize
  end

  def format_seconds(seconds)
    hours = (seconds / 3600).to_i
    minutes = ((seconds % 3600) / 60).to_i
    secs = (seconds % 60).to_i

    format('%02d:%02d:%02d', hours, minutes, secs)
  end

  def expect_response_success?(response:)
    build_message = lambda do |res|
      "Validate API\n" \
      "Status Code: #{res.code}\n" \
      "URL: #{res.request.http_method.to_s.split('::').last.upcase} #{res.request.last_uri}\n" \
      "Content: #{res.parsed_response}\n\n"
    end

    unless response.success? && response.code != 422
      message = build_message.call(response)
      raise ApiError, message
    end
    true
  end
end
