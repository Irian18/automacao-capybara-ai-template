require_relative 'google_sheets_helper'
require_relative 'hash_helper'
require_relative 'credentials_helper'
require_relative 'test_environment_manager_helper'
require_relative 'intercept_request_helper'

module DriverHelper

  def current_session
    Capybara.current_session
  end

  def current_driver
    Capybara.current_driver
  end

  def ferrum_browser
    return nil unless cuprite_driver?

    # No Cuprite, o browser é uma instância Ferrum
    current_session.driver.browser
  end

  def cuprite_driver?
    current_driver == :cuprite
  end

  def firefox_driver?
    [:selenium, :firefox, :firefox_headless].include?(current_driver)
  end

  def devtools
    return nil unless cuprite_driver?

    # Ferrum expõe o devtools diretamente
    ferrum_browser.devtools
  end

  def execute_cdp(command, params = {})
    return nil unless cuprite_driver?

    # Executa comando Chrome DevTools Protocol
    ferrum_browser.command(command, params)
  rescue => e
    puts "[WARN] Falha ao executar CDP #{command}: #{e.message}"
    nil
  end

  def resize_window(width:, height:)
    if cuprite_driver?
      ferrum_browser.resize(width: width, height: height)
    else
      # Fallback para Selenium se necessário
      current_session.driver.browser.manage.window.resize_to(width, height)
    end
  end

  def maximize_window
    if cuprite_driver?
      # Ferrum não tem maximize nativo, usa tamanho grande padrão
      ferrum_browser.resize(width: 1920, height: 1080)
    else
      current_session.driver.browser.manage.window.maximize
    end
  end

  def fullscreen_window
    return unless cuprite_driver?

    ferrum_browser.command('Emulation.setDeviceMetricsOverride',
      width: 1920,
      height: 1080,
      deviceScaleFactor: 1,
      mobile: false
    )
  end

  def screenshot(path: nil, full: true)
    return nil unless cuprite_driver?

    path ||= "report/screenshots/#{Time.now.strftime('%Y%m%d_%H%M%S')}.png"
    FileUtils.mkdir_p(File.dirname(path))

    if full
      ferrum_browser.screenshot(path: path, full: true)
    else
      ferrum_browser.screenshot(path: path)
    end

    path
  end


  def clear_browser_data
    return false unless cuprite_driver?

    begin
      ferrum_browser.cookies.clear

      execute_cdp('Storage.clearDataForOrigin',
        origin: '*',
        storageTypes: 'all'
      )

      execute_cdp('Network.clearBrowserCache')

      execute_cdp('Network.clearBrowserCookies')

      true
    rescue => e
      puts "[WARN] Falha ao limpar dados do navegador: #{e.message}"
      false
    end
  end

  def clear_cookies
    return false unless cuprite_driver?

    ferrum_browser.cookies.clear
    true
  rescue => e
    puts "[WARN] Falha ao limpar cookies: #{e.message}"
    false
  end

  def set_cookie(name, value, **options)
    return false unless cuprite_driver?

    default_options = {
      name: name,
      value: value,
      domain: URI(CONFIG['url_home']).host,
      path: '/',
      expires: (Time.now + 1.day).to_i
    }

    ferrum_browser.cookies.set(**default_options.merge(options))
    true
  rescue => e
    puts "[WARN] Falha ao setar cookie: #{e.message}"
    false
  end

  def get_cookies
    return [] unless cuprite_driver?

    ferrum_browser.cookies.all
  rescue => e
    puts "[WARN] Falha ao obter cookies: #{e.message}"
    []
  end

  def network
    return nil unless cuprite_driver?

    ferrum_browser.network
  end

  def intercept_network
    return false unless cuprite_driver?

    network.intercept
    true
  end

  def stop_network_interception
    return false unless cuprite_driver?

    network.disable_interception
    true
  end

  def clear_network_traffic
    return false unless cuprite_driver?

    network.clear(:traffic)
    true
  end

  def network_traffic
    return [] unless cuprite_driver?

    network.traffic
  end

  def execute_script(script, *args)
    current_session.execute_script(script, *args)
  end

  def evaluate_script(script, *args)
    current_session.evaluate_script(script, *args)
  end

  def evaluate_async_script(script, *args)
    current_session.evaluate_async_script(script, *args)
  end

  def wait_for_stable_page(wait_time: 2)
    return false unless cuprite_driver?

    start_time = Time.now

    loop do
      traffic = network.traffic
      pending = traffic.count { |t| t.response.nil? }

      return true if pending == 0
      return false if (Time.now - start_time) > wait_time

      sleep 0.1
    end
  end

  def wait_for_ajax(timeout: Capybara.default_max_wait_time)
    current_session.has_no_css?('.loading, .ajax-loading', wait: timeout)
  rescue
    true
  end

  def add_headers(headers)
    return false unless cuprite_driver?

    ferrum_browser.headers.add(headers)
    true
  rescue => e
    puts "[WARN] Falha ao adicionar headers: #{e.message}"
    false
  end

  def set_basic_auth(user:, password:)
    return false unless cuprite_driver?

    ferrum_browser.headers.add(
      'Authorization' => "Basic #{Base64.strict_encode64("#{user}:#{password}")}"
    )
    true
  rescue => e
    puts "[WARN] Falha ao setar auth: #{e.message}"
    false
  end

  def console_logs
    return [] unless cuprite_driver?

    ferrum_browser.console_logs
  rescue => e
    puts "[WARN] Falha ao obter console logs: #{e.message}"
    []
  end

  def clear_console_logs
    return false unless cuprite_driver?

    ferrum_browser.clear_console_logs
    true
  rescue => e
    puts "[WARN] Falha ao limpar console logs: #{e.message}"
    false
  end


  def emulate_mobile_device(device_type: :iphone_x)
    return false unless cuprite_driver?

    devices = {
      iphone_x: { width: 375, height: 812, device_scale_factor: 3, mobile: true },
      iphone_se: { width: 375, height: 667, device_scale_factor: 2, mobile: true },
      ipad: { width: 768, height: 1024, device_scale_factor: 2, mobile: true },
      pixel_5: { width: 393, height: 851, device_scale_factor: 2.75, mobile: true }
    }

    device = devices[device_type] || devices[:iphone_x]

    execute_cdp('Emulation.setDeviceMetricsOverride',
      width: device[:width],
      height: device[:height],
      deviceScaleFactor: device[:device_scale_factor],
      mobile: device[:mobile]
    )

    execute_cdp('Emulation.setUserAgentOverride',
      userAgent: mobile_user_agent(device_type)
    )

    true
  end

  def reset_emulation
    return false unless cuprite_driver?

    execute_cdp('Emulation.clearDeviceMetricsOverride')
    execute_cdp('Emulation.setUserAgentOverride', userAgent: '')

    true
  end

  def save_pdf(path:, **options)
    return false unless cuprite_driver?

    default_options = {
      path: path,
      landscape: false,
      print_background: true,
      prefer_css_page_size: true
    }

    ferrum_browser.pdf(**default_options.merge(options))
    true
  rescue => e
    puts "[WARN] Falha ao gerar PDF: #{e.message}"
    false
  end


  def page_source
    current_session.html
  end

  def current_url
    current_session.current_url
  end

  def refresh_page
    current_session.refresh
  end

  def go_back
    current_session.go_back
  end

  def go_forward
    current_session.go_forward
  end

  def switch_to_frame(frame)
    current_session.switch_to_frame(frame)
  end

  def switch_to_default_frame
    current_session.switch_to_frame(:top)
  end

  def open_new_tab(url = nil)
    return nil unless cuprite_driver?

    target_id = execute_cdp('Target.createTarget', url: url || 'about:blank')
                              .dig('result', 'targetId')

    execute_cdp('Target.activateTarget', targetId: target_id)

    target_id
  end

  def close_tab(target_id)
    return false unless cuprite_driver?

    execute_cdp('Target.closeTarget', targetId: target_id)
    true
  end

  def get_all_tabs
    return [] unless cuprite_driver?

    result = execute_cdp('Target.getTargets')
    result.dig('result', 'targetInfos') || []
  end

  private

  def mobile_user_agent(device_type)
    agents = {
      iphone_x: 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_0 like Mac OS X) AppleWebKit/605.1.15',
      iphone_se: 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_0 like Mac OS X) AppleWebKit/605.1.15',
      ipad: 'Mozilla/5.0 (iPad; CPU OS 13_0 like Mac OS X) AppleWebKit/605.1.15',
      pixel_5: 'Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36'
    }

    agents[device_type] || agents[:iphone_x]
  end
end

World(DriverHelper) if defined?(World)
