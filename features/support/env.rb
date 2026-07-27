require 'base64'
require 'capybara'
require 'capybara/dsl'
require 'selenium-webdriver'
require 'site_prism'
require 'faker'
require 'date'
require 'cpf_faker'
require 'debug'
require 'pry-byebug'
require 'httparty'
require 'allure-cucumber'
require 'allure-ruby-commons'
require 'capybara/cucumber'
require 'cucumber/core'
require 'cucumber/core/filter'
require 'json'
require 'open3'
require 'dry-struct'
require 'time'
require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'
require 'socket'
require 'capybara/cuprite'
require 'ferrum'
require 'dotenv/load'
require_relative 'page_helper'
require_relative 'helpers/helper'
require_relative 'helpers/service_helper'
require_relative 'helpers/intercept_request_helper'
require 'matrix'
require_relative 'helpers/siteprism_helper'
require_relative 'self_healing/agent' if ENV['SELF_HEALING_ENABLED'] == 'true'

Dir[File.join(File.dirname(__FILE__), 'helpers', '*.rb')].sort.each { |file| require_relative file }

World(HTTParty)
World(Capybara::DSL)
World(Capybara::RSpecMatchers)
World(Pages)
World(AppServices)
World(CredentialsHelper)
World(DriverHelper)
World(GoogleSheetsHelper)
World(HashHelper)
World(TestEnvironmentManagerHelper)
World(Helper)
World(SitePrismHelper)

# World(Interceptor)

ENVIRONMENT_TYPE = ENV['ENVIRONMENT_TYPE']
CONFIG = YAML.load_file(File.dirname(__FILE__) + "/environments/#{ENVIRONMENT_TYPE}.yml")


HashHelper.initialize_hash_credentials
HashHelper.initialize_hash_response_error
HashHelper.initialize_hash_response_full

def find_available_port
  loop do
    port = rand(1000..9999)
    begin
      TCPServer.new('127.0.0.1', port).close
      return port
    rescue Errno::EADDRINUSE
      next
    end
  end
end

@headless_mode = CONFIG['headless_mode']

Capybara.register_driver :cuprite do |app|
  browser_options = {
    'no-sandbox' => nil,
    'disable-gpu' => nil,
    'disable-dev-shm-usage' => nil
  }

  driver_options = {
    inspector: true,
    pending_connection_errors: true,
    pending_connection_timeout: 10,
    timeout: 10,
    process_timeout: 10,
    headless: @headless_mode,
    browser_options:,
    base_url: CONFIG['url_home']
    # ,
    # window_size: [1280, 1080]
  }

  Capybara::Cuprite::Driver.new(app, driver_options)
end

Capybara.default_driver = :cuprite
Capybara.javascript_driver = :cuprite
Capybara.current_driver = :cuprite

Before do
  page.driver.add_headers(
    'Origin' => CONFIG['url_home'],
    'Referer' => CONFIG['url_home']
  )

  unless CONFIG['headless_mode']
    targets = page.driver.browser.command('Target.getTargets')
    page_target = targets['targetInfos']&.find { |t| t['type'] == 'page' }
    if page_target
      result = page.driver.browser.command('Browser.getWindowForTarget', targetId: page_target['targetId'])
      page.driver.browser.command(
        'Browser.setWindowBounds',
        windowId: result['windowId'],
        bounds: { windowState: 'maximized' }
      )
      sleep 0.3
      bounds = page.driver.browser.command('Browser.getWindowBounds', windowId: result['windowId'])
      w = bounds['bounds']['width']
      h = bounds['bounds']['height']
      
      page.driver.browser.page.command(
        'Emulation.setDeviceMetricsOverride',
        width: w,
        height: h,
        deviceScaleFactor: 0,
        mobile: false
      )
    end
  end
end

Capybara.configure do |config|
  config.run_server = false
  config.app_host = CONFIG['url_home']
  config.always_include_port = false
  config.raise_server_errors = false
  config.default_max_wait_time = 60
  config.default_retry_interval = 0.1
  config.automatic_reload = true
  config.predicates_wait = true
  config.default_selector = :css
  config.match            = :smart
  config.exact            = false
  config.exact_text       = false
  config.test_id = 'data-test-id'
  config.enable_aria_label = true
  config.enable_aria_role  = true
  config.automatic_label_click = true
  config.ignore_hidden_elements = true
  config.w3c_click_offset = true
  config.save_path = File.expand_path('tmp/capybara', Dir.pwd)
  config.threadsafe = false
  config.server_port = find_available_port
end

Allure.configure do |config|
  config.results_directory = 'report/allure_results'
  config.clean_results_directory = true
  config.logging_level = Logger::INFO
  config.logger = Logger.new($stdout, level: config.logging_level)
  config.environment = ENVIRONMENT_TYPE
  config.link_tms_pattern = ENV['ALLURE_TMS_PATTERN'] || ''
  config.link_issue_pattern = ENV['ALLURE_ISSUE_PATTERN'] || ''
  config.environment_properties = lambda do
    {
      'Application' => ENV['APPLICATION_NAME'] || 'Application',
      'Environment' => ENVIRONMENT_TYPE,
      'Base URL' => CONFIG['url_home'],
      'Ruby Version' => RUBY_VERSION,
      'Ruby Platform' => RUBY_PLATFORM,
      'Capybara' => Capybara::VERSION,
      'Browser' => CONFIG['headless_mode'] ? 'Chrome Headless' : 'Chrome',
      'Headless' => CONFIG['headless_mode'],
      'Executed At' => Time.now.strftime('%Y-%m-%d %H:%M:%S %Z')
    }.compact.reject { |_, v| v.to_s.empty? }
  end
end
