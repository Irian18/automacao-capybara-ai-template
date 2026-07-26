require_relative 'google_sheets_helper'
require_relative 'hash_helper'
require_relative 'credentials_helper'
require_relative 'test_environment_manager_helper'
require_relative 'driver_helper'

class CupriteInterceptor
  include Capybara::DSL

  attr_reader :requests, :responses, :timing_data, :total_request,
              :total_response, :errors, :performance_metrics

  def initialize
    @session = Capybara.current_session
    @browser = @session.driver.browser

    @requests = {}
    @responses = {}
    @timing_data = {}
    @errors = []
    @performance_metrics = { results: {} }

    @total_request = 0
    @total_response = 0
    @total = 0
    @interception_active = false
    @interception_thread = nil
  end


  MAX_INTERCEPTION_TIME = 10 
  CHECK_INTERVAL = 0.1      

  def start_interception(auto_stop: true)
    return false unless cuprite_driver?

    @interception_active = true
    @auto_stop_enabled = auto_stop
    reset_data

    @browser.network.intercept
    start_traffic_monitoring

    start_auto_stop_thread if auto_stop

    true
  end

  def stop_interception
    @interception_active = false
    @auto_stop_thread&.kill
    @interception_thread&.kill

    collect_traffic_data

    {
      requests_count: @requests.size,
      responses_count: @responses.size,
      timing_entries: @timing_data.size,
      auto_stopped: @auto_stopped || false
    }
  end

  private

  def start_auto_stop_thread
    @auto_stop_thread = Thread.new do
      start_time = Time.now

      loop do
        elapsed = Time.now - start_time

        if @responses.size >= @requests.size && @requests.size > 0
          @auto_stopped = true
          puts "[Auto-Stop] Todas as requisições respondidas: #{@responses.size}/#{@requests.size}" if debug?
          stop_interception
          break
        end

        if elapsed >= MAX_INTERCEPTION_TIME
          @auto_stopped = true
          if debug?
            puts "[Auto-Stop] Timeout atingido: #{elapsed.round(2)}s | Requests: #{@requests.size}, Responses: #{@responses.size}"
          end
          stop_interception
          break
        end

        sleep CHECK_INTERVAL
      end
    end
  end

  def reset_interception
    stop_interception
    reset_data
    @browser.network.clear(:traffic) if cuprite_driver?
    true
  end

  private

  def reset_data
    @requests.clear
    @responses.clear
    @timing_data.clear
    @total_request = 0
    @total_response = 0
    @total = 0
  end

  def start_traffic_monitoring
    @interception_thread = Thread.new do
      while @interception_active
        begin
          collect_traffic_data
          sleep 0.1
        rescue StandardError => e
          @errors << "Erro no monitoramento: #{e.message}"
        end
      end
    end
  end

  def collect_traffic_data
    return unless cuprite_driver?

    traffic = @browser.network.traffic

    traffic.each do |exchange|
      next unless exchange

      process_request(exchange.request) if exchange.request && !request_processed?(exchange.request)

      process_response(exchange, exchange.response) if exchange.response && !response_processed?(exchange)
    end
  end

  def request_processed?(request)
    @requests.values.any? { |r| r[:url] == request.url && r[:method] == request.method }
  end

  def response_processed?(exchange)
    @responses.values.any? { |r| r[:url] == exchange.response.url }
  end

  def process_request(request)
    return unless should_intercept?(request.url, request.method)

    @total_request += 1

    receipt_time = Time.now

    @requests[@total_request] = {
      id: @total_request,
      url: request.url,
      method: request.method,
      headers: request.headers.to_h,
      time: {
        receipt_time:,
        wall_time: receipt_time.to_f,
        wall_time_formatted: receipt_time.strftime('%d/%m/%y %H:%M:%S')
      }
    }

    puts "[Request #{@total_request}] #{request.method} #{truncate_url(request.url)}" if debug?
  end

  def process_response(exchange, response)
    return unless should_intercept_url?(response.url)

    request_id = find_request_id_by_url(response.url)
    return unless request_id

    @total_response += 1
    receipt_time = Time.now

    body_size = calculate_body_size(response)
    x_page_boo = !response.headers['x-page'].nil?

    x_runtime_raw = response.headers['x-runtime']
    x_runtime_seconds = x_runtime_raw.to_f.round(3)

    @responses[request_id] = {
      id: request_id,
      url: response.url,
      status: response.status,
      status_text: response.status_text,
      headers: response.headers.to_h.merge(
        'receipt_time' => receipt_time,
        'receipt_time_formatted' => receipt_time.strftime('%d/%m/%y %H:%M:%S'),
        'payload_size_bytes' => body_size,
        'payload_size_kb' => (body_size / 1024.0).round(3),
        'x_runtime' => x_runtime_seconds,
        'x-total' => response.headers['x-total'],
        'x_page?' => x_page_boo
      )
    }

    if @requests[request_id]
      req_time = @requests[request_id][:time][:receipt_time]
      res_time = receipt_time

      @timing_data[request_id] = {
        route: extract_path_safe(response.url),
        total_time_ms: ((res_time - req_time) * 1000).round(3),
        start_time: req_time,
        end_time: res_time
      }
    end

    return unless debug?

    puts "[Response #{request_id}] #{response.status} #{truncate_url(response.url)} (#{@timing_data[request_id]&.dig(:total_time_ms)}ms)"
  end

  def find_request_id_by_url(url)
    @requests.find { |id, req| req[:url] == url }&.first
  end

  def should_intercept?(url, method)
    return false unless method == 'GET'

    should_intercept_url?(url)
  end

  def should_intercept_url?(url)
    api_base_url = ENV['API_BASE_URL'] || CONFIG['base_uri']
    return false unless api_base_url && url.start_with?(api_base_url)

    excluded_paths = ENV['INTERCEPT_EXCLUDED_PATHS']&.split(',') || [
      '/auth/validate_token',
      '/access_profiles/validate'
    ]

    excluded_paths.none? { |path| url.include?(path) }
  end

  public

  def debug?
    ENV['DEBUG_INTERCEPTOR'] == 'true'
  end

  def get_request(id)
    @requests[id]
  end

  def get_response(id)
    @responses[id]
  end

  def get_timing(id)
    @timing_data[id]
  end

  def full_responses
    @responses
  end

  def full_requests
    @requests
  end

  def page_loading_time
    return { minutes: 0, seconds: 0, total_seconds: 0 } if @requests.empty? || @responses.empty?

    first_request_time = @requests.values.first&.dig(:time, :receipt_time)
    last_response_time = @responses.values.last&.dig(:headers, 'receipt_time')

    return { minutes: 0, seconds: 0, total_seconds: 0 } unless first_request_time && last_response_time

    duration = last_response_time - first_request_time # segundos

    {
      minutes: (duration / 60).to_i,
      seconds: (duration % 60).round(3), # segundos com 3 decimais
      total_seconds: duration.round(3) # segundos totais com 3 decimais
    }
  end

  def full_responses_detailed
    result = {}

    @responses.each do |id, response|
      request = @requests[id]
      timing = @timing_data[id]

      if request && response
        req_time = request.dig(:time, :receipt_time)
        res_time = response.dig(:headers, 'receipt_time')
        # Diferença em segundos com 3 casas decimais
        time_routes = if req_time && res_time
                        (res_time - req_time).round(3)
                      else
                        0.0
                      end
      else
        time_routes = 0.0
      end

      result[id] = {
        initial_page_date: @requests.values.first&.dig(:time, :receipt_time)&.strftime('%d/%m/%Y %H:%M:%S'),
        route: extract_path_safe(response[:url]),
        method: request&.dig(:method),
        status: response[:status],
        payload_size_kb: response.dig(:headers, 'payload_size_kb'),
        x_page?: response.dig(:headers, 'x_page?'),
        time_route: @timing_data[id]&.dig(:total_time_ms), # SEGUNDOS (ex: 0.091)
        x_runtime: response.dig(:headers, 'x_runtime'),
        x_total: response.dig(:headers, 'x-total'),
        page: current_page_path,
        time_page: page_loading_time[:seconds],
        wallTime_request: request&.dig(:time, :wall_time_formatted),
        response_time: response.dig(:headers, 'receipt_time_formatted')
      }
    end

    result
  end

  def high_response_time(max_time_ms)
    @timing_data.select do |id, timing|
      timing[:total_time_ms] > max_time_ms
    end.transform_values do |timing|
      {
        route: timing[:route],
        time_ms: timing[:total_time_ms],
        status: @responses[id]&.dig(:status)
      }
    end
  end

  def low_response_time(min_time_ms)
    @timing_data.select do |id, timing|
      timing[:total_time_ms] < min_time_ms
    end.transform_values do |timing|
      {
        route: timing[:route],
        time_ms: timing[:total_time_ms],
        status: @responses[id]&.dig(:status)
      }
    end
  end

  def page_loading_time
    return { minutes: 0, seconds: 0, total_seconds: 0 } if @requests.empty? || @responses.empty?

    # CORREÇÃO: Variáveis corretas
    first_request_time = @requests.values.first&.dig(:time, :receipt_time)
    last_response_time = @responses.values.last&.dig(:headers, 'receipt_time')

    return { minutes: 0, seconds: 0, total_seconds: 0 } unless first_request_time && last_response_time

    # CORREÇÃO: Ordem correta (response - request)
    duration_page = last_response_time - first_request_time

    {
      minutes: (duration_page / 60).to_i,
      seconds: (duration_page % 60).round(3),
      total_seconds: duration_page.round(3)
    }
  end

  def formatted_summary
    data = full_responses_detailed

    puts "\n" + '=' * 80
    puts "RESUMO DE REQUISIÇÕES: #{data.size} requests capturados \nPAGINA: #{current_page_path} - TEMPO DE CARREGAMENTO DA PAGINA: #{format(
      '%.3f', page_loading_time[:total_seconds]
    )}s"
    puts '=' * 80

    sorted = data.sort_by { |id, info| -(info[:time_route] || 0) }

    sorted.each do |id, info|
      status_icon = info[:status].to_s.start_with?('2') ? '✓' : '✗'
      time_icon = info[:time_route] > 5.0 ? '✓' : '✗'

      # CORREÇÃO: Threshold em segundos (não ms)
      time_seconds = info[:time_route] || 0
      time_color = if time_seconds > 5.0
                     '🔴'
                   elsif time_seconds > 3.0
                     '🟡'
                   else
                     '🟢'
                   end

      status_color = if !info[:status].to_s.start_with?('2')
                       '🔴'
                     elsif time_seconds > 3.0
                       '🟡'
                     else
                       '🟢'
                     end

      time_formatted = format('%.3f', time_seconds)

      puts "\n[#{id.to_s.rjust(2)}] #{time_icon} #{time_color} #{info[:method]} #{info[:route]}"
      puts "         #{status_icon} #{status_color} Status: #{info[:status]} | Time: #{time_formatted}s | X-Runtime: #{info[:x_runtime]}s"
      puts "         Payload: #{info[:payload_size_kb]} KB | X-Page: #{info[:x_page?]}"
      puts "         Request: #{info[:wallTime_request]} | Response: #{info[:response_time]}"
    end

    puts "\n" + '=' * 80 + "\n\n"
  end

  def slow_requests_table(threshold_seconds: 0.5) # threshold em segundos
    slow = full_responses_detailed.select do |id, info|
      (info[:time_route] || 0) > threshold_seconds
    end

    puts "\n" + '=' * 80
    puts "REQUESTS LENTOS (> #{threshold_seconds}s): #{slow.size}"
    puts '-' * 80
    puts "#{'ID'.rjust(4)} | #{'ROUTE'.ljust(50)} | #{'TIME'.rjust(10)} | #{'STATUS'.rjust(6)}"
    puts '-' * 80

    slow.sort_by { |id, info| -info[:time_route] }.each do |id, info|
      time_str = format('%.3f', info[:time_route])
      puts "#{id.to_s.rjust(4)} | #{info[:route][0..48].ljust(50)} | #{time_str.rjust(8)}s | #{info[:status].to_s.rjust(6)}"
    end

    puts '=' * 80
    slow
  end

  def capture_performance_metrics
    return {} unless cuprite_driver?

    time_key = Time.now.strftime('%Y-%m-%d %H:%M:%S')

    metrics = {
      cdp: fetch_cdp_metrics,
      memory: fetch_memory_metrics,
      navigation: fetch_navigation_metrics,
      summary: {
        total_requests: @requests.size,
        total_responses: @responses.size,
        pending_requests: @requests.size - @responses.size
      }
    }

    @performance_metrics[:results][time_key] = metrics
    save_metrics_to_file(time_key, metrics)

    metrics
  end

  def wait_for_interception_completion(timeout: 30)
    start_time = Time.now

    loop do
      pending = @requests.size - @responses.size
      puts "Aguardando... Requests: #{@requests.size}, Responses: #{@responses.size}, Pending: #{pending}" if debug?

      break if pending == 0 && @requests.size > 0
      break if (Time.now - start_time) > timeout

      sleep 0.2
    end

    stop_interception

    {
      completed: @requests.size == @responses.size,
      requests: @requests.size,
      responses: @responses.size,
      pending: @requests.size - @responses.size,
      duration: (Time.now - start_time).round(2)
    }
  end

  def visit_page(path)
    url = "#{CONFIG['url_home']}#{path}"
    puts "Navegando para: #{url}" if debug?
    @session.driver.visit(url)
    wait_for_page_stable
  end

  def wait_for_page_stable(timeout: 10)
    start_time = Time.now

    loop do
      pending = @browser.network.traffic.count { |e| e.response.nil? }

      return true if pending == 0
      return false if (Time.now - start_time) > timeout

      sleep 0.2
    end
  end

  def interception_summary
    {
      total_requests: @total_request,
      total_responses: @total_response,
      requests_hash_size: @requests.size,
      responses_hash_size: @responses.size,
      timing_data_size: @timing_data.size,
      pending: @requests.size - @responses.size,
      errors: @errors
    }
  end

  private

  def cuprite_driver?
    Capybara.current_driver == :cuprite
  end

  def calculate_body_size(response)
    return 0 unless response.body

    response.body.to_s.bytesize
  rescue StandardError => e
    @errors << "Erro ao calcular body size: #{e.message}"
    0
  end

  def extract_path_safe(url)
    URI.parse(url).request_uri
  rescue URI::Error, ArgumentError => e
    @errors << "Erro ao parsear URL #{url}: #{e.message}"
    url
  end

  def truncate_url(url, max: 80)
    url.length > max ? "#{url[0..max]}..." : url
  end

  def current_page_path
    uri = URI(page.current_url)
    "#{uri.request_uri}#{uri.fragment ? "##{uri.fragment}" : ''}"
  rescue StandardError
    '/'
  end

  def fetch_cdp_metrics
    response = @browser.command('Performance.getMetrics')
    metrics = response.dig('result', 'metrics') || []

    metrics.each_with_object({}) do |item, hash|
      hash[item['name']] = item['value']
    end
  rescue StandardError => e
    @errors << "Erro CDP: #{e.message}"
    {}
  end

  def fetch_memory_metrics
    page.evaluate_script('window.performance.memory') || {}
  rescue StandardError => e
    @errors << "Erro Memory: #{e.message}"
    {}
  end

  def fetch_navigation_metrics
    entries = page.evaluate_script("window.performance.getEntriesByType('navigation')") || []
    entries.first || {}
  rescue StandardError => e
    @errors << "Erro Navigation: #{e.message}"
    {}
  end

  def save_metrics_to_file(timestamp, data)
    dir = 'report/performance_metrics'
    FileUtils.mkdir_p(dir)

    filename = "#{dir}/cuprite_#{timestamp.gsub(/[:\s]/, '_')}.json"

    File.open(filename, 'w') { |f| f.write(JSON.pretty_generate(data)) }
  rescue StandardError => e
    @errors << "Erro ao salvar: #{e.message}"
  end
end
