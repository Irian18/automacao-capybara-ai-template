World(Helper)

include Helper

ALLURE_CATEGORIES_FILE = File.expand_path('allure/categories.json', __dir__).freeze

BeforeAll do
  results_dir = Allure.configuration.results_directory
  FileUtils.mkdir_p(results_dir)
  FileUtils.cp(ALLURE_CATEGORIES_FILE, File.join(results_dir, 'categories.json'))
  $all_scenario_tags = []
end

Before '@skip_in_ci' do
  skip_this_scenario if ENV['ENVIRONMENT_TYPE'] == 'ci'
end

Before '@local_only' do
  skip_this_scenario unless ENV['ENVIRONMENT_TYPE'] == 'local'
end

Before '@logar_usuario' do |_scenario|
  login.load_and_wait
  wait_page_full_load
  login.logar_usuario(CONFIG['email'], CONFIG['password'])
  wait_page_full_load
end

After '@teardown' do
  exec_teardown
end

After '@teardown_on_failure' do |scenario|
  exec_teardown if scenario.failed?
end

Before do |scenario|
  current_tags = scenario.tags.map(&:name)
  $all_scenario_tags |= current_tags

  skip_this_scenario if current_tags.include?('@performance') && ENV['ENVIRONMENT_TYPE'] != 'prod_performance'

  @scenario = scenario
  @scenario_name = scenario.name.to_s.gsub(/[^a-zA-Z0-9_-]/, '_')[0, 80]
  @video_frames  = []
  capture_video_frame
  sleep 0.5
  generate_access_credentials_v1(email: CONFIG['email_api_v1'], password: CONFIG['password_api_v1']) if respond_to?(:login_service)
  sleep 0.5
end

AfterStep do |result, step|
  capture_video_frame

  next unless result.failed?

  begin
    if defined?(Capybara) && Capybara.current_session.driver.respond_to?(:save_screenshot)
      screenshot_path = File.join(
        Capybara.save_path,
        "step_fail_#{@scenario_name}_#{Time.now.to_i}.png"
      )
      Capybara.current_session.save_screenshot(screenshot_path, full: true)

      Allure.add_attachment(
        name: "Screenshot do step: #{step.text}"[0, 100],
        source: File.open(screenshot_path),
        type: Allure::ContentType::PNG,
        test_case: true
      )
    end
  rescue StandardError => e
    Allure.configuration.logger.warn("Falha ao anexar screenshot do step: #{e.message}")
  end
end

After do |scenario|
  page = Capybara.current_session

  attach_scenario_video
  next unless scenario.failed?

  begin
    attach_final_screenshot(page)
    attach_dom(page)
    attach_failure_context(page, scenario)
    attach_failed_requests(page)
  rescue StandardError => e
    Allure.configuration.logger.warn("Falha ao anexar evidências da falha: #{e.message}")
  end
end

def capture_video_frame
  drv = Capybara.current_session.driver
  return unless drv.respond_to?(:render_base64)

  raw = drv.render_base64(:jpeg, quality: 75, full: false)
  (@video_frames ||= []) << Base64.strict_decode64(raw) if raw
rescue StandardError
  nil
end

def attach_scenario_video
  capture_video_frame

  frames = Array(@video_frames).compact
  return if frames.empty?

  video_path = File.join(
    Capybara.save_path,
    "report/videos/#{@scenario_name}_#{Time.now.strftime('%d-%m-%y_%H-%M-%S')}.mp4"
  )
  FileUtils.mkdir_p(File.dirname(video_path))

  framerate = frames.size > 10 ? 5 : 2

  Dir.mktmpdir do |tmp|
    frames.each_with_index do |frame, idx|
      File.binwrite(File.join(tmp, format('frame_%06d.jpg', idx)), frame)
    end
    system(
      'ffmpeg', '-y', '-loglevel', 'quiet',
      '-framerate', framerate.to_s,
      '-i', File.join(tmp, 'frame_%06d.jpg'),
      '-c:v', 'libx264', '-pix_fmt', 'yuv420p',
      '-vf', 'scale=trunc(iw/2)*2:trunc(ih/2)*2',
      video_path, out: File::NULL, err: File::NULL
    )
  end

  return unless File.exist?(video_path) && File.size(video_path).positive?

  Allure.add_attachment(
    name: 'Vídeo da execução',
    source: File.open(video_path),
    type: 'video/mp4',
    test_case: true
  )
rescue StandardError => e
  Allure.add_attachment(
    name: 'Erro ao gerar vídeo',
    source: "#{e.class}: #{e.message}\n#{Array(e.backtrace).first(5).join("\n")}",
    type: Allure::ContentType::TXT,
    test_case: true
  )
end

def attach_final_screenshot(page)
  return unless page.driver.respond_to?(:save_screenshot)

  path = File.join(
    Capybara.save_path,
    "report/screenshots/#{@scenario_name}_#{Time.now.strftime('%d-%m-%y_%H-%M-%S')}.png"
  )
  FileUtils.mkdir_p(File.dirname(path))
  page.save_screenshot(path, full: true)
  Allure.add_attachment(
    name: 'Screenshot final da falha',
    source: File.open(path),
    type: Allure::ContentType::PNG,
    test_case: true
  )
end

def attach_dom(page)
  Allure.add_attachment(
    name: 'DOM no momento da falha',
    source: page.html,
    type: 'text/html',
    test_case: true
  )
end

def attach_failure_context(page, scenario)
  context = [
    "URL atual:    #{page.current_url}",
    "Título:       #{page.title}",
    "Cenário:      #{scenario.name}",
    "Localização:  #{scenario.location}",
    "Tags:         #{scenario.tags.map(&:name).join(' ')}",
    '',
    'Exceção:',
    scenario.exception&.message.to_s,
    '',
    'Backtrace (top 15):',
    Array(scenario.exception&.backtrace).first(15).join("\n")
  ].join("\n")

  Allure.add_attachment(
    name: 'Contexto da falha',
    source: context,
    type: Allure::ContentType::TXT,
    test_case: true
  )
end

def attach_failed_requests(page)
  return unless defined?(Capybara::Cuprite) &&
                page.driver.respond_to?(:browser) &&
                page.driver.browser.respond_to?(:network)

  api_base = CONFIG['base_uri'] || CONFIG['url_home']
  failed = page.driver.browser.network.traffic
               .reject { |e| e.response.nil? }
               .select { |e| e.response.status >= 400 && api_base && e.response.url.start_with?(api_base) }
               .map    { |e| "#{e.response.status}  #{e.request.method.to_s.ljust(6)}  #{e.request.url}" }

  return if failed.empty?

  Allure.add_attachment(
    name: 'Requisições com erro (>= 400)',
    source: failed.join("\n"),
    type: Allure::ContentType::TXT,
    test_case: true
  )
end

at_exit do
  environment_type = ENV['ENVIRONMENT_TYPE']

  helper = Object.new
  helper.extend(AppServices)
  helper.extend(TestEnvironmentManagerHelper)

  helper.exec_teardown if environment_type == 'local'

  system('rm -rf tmp/capybara/report/videos')
  system('rm -rf tmp/capybara/report/screenshots')

  # Em CI preservamos os resultados do Allure para geração do relatório
  unless environment_type == 'ci'
    system('rm -rf report/allure_results/*')
  end

  helper.terminate_chrome_browser
end
