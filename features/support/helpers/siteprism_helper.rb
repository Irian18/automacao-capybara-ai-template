require 'json'
require 'fileutils'
require_relative '../self_healing/config'
require_relative '../self_healing/api_client'
require_relative '../self_healing/prompt_loader'

module SitePrismHelper
  PO_SYSTEM_CONTENT = 'Você é um engenheiro sênior de QA especialista em SitePrism, ' \
                      'Capybara e Ruby. Responda SOMENTE com código Ruby válido, ' \
                      'sem markdown, sem explicações.'.freeze

  def generate_siteprism_page(html:, url:, nome_page:, output_dir: 'tmp/page_objects/generated')
    puts "[Helper] Gerando página SitePrism para: #{nome_page}"

    cleaned_html = sanitize_html(html)
    prompt       = SelfHealing::PromptLoader.render('siteprism_generator',
                                           nome_page:,
                                           url:,
                                           html: cleaned_html,
                                           page_object_design_system: SelfHealing::PromptLoader.read_page_object_prompt)

    client   = SelfHealing::ApiClient.new(model: SelfHealing::Config.po_model)
    begin
      raw_code = client.complete(prompt, system_content: PO_SYSTEM_CONTENT)
    rescue StandardError => e
      puts "[Helper] ERRO na chamada da API: #{e.class}: #{e.message}"
      raise
    end

    puts "[Helper] Resposta da API: #{raw_code.to_s.length} caracteres"
    raise "[Helper] API retornou resposta vazia para #{nome_page}" if raw_code.nil? || raw_code.to_s.strip.empty?

    rb_code  = extract_ruby_code(raw_code)
    puts "[Helper] Código Ruby extraído: #{rb_code.length} caracteres"
    raise "[Helper] Código Ruby extraído ficou vazio para #{nome_page}" if rb_code.strip.empty?

    save_page_file(rb_code, nome_page, output_dir)

    rb_code
  end

  private

  def sanitize_html(html)
    cleaned = html
              .gsub(%r{<script\b[^>]*>.*?</script>}mi, '')
              .gsub(%r{<style\b[^>]*>.*?</style>}mi, '')
              .gsub(/<!--.*?-->/m, '')
              .gsub(/\sstyle="[^"]*"/, '')
              .gsub(/\son\w+="[^"]*"/, '')
              .gsub(/\s{2,}/, ' ')
              .strip

    max_chars = 12_000
    if cleaned.length > max_chars
      puts "[Helper] HTML truncado de #{cleaned.length} para #{max_chars} caracteres."
      cleaned = cleaned[0...max_chars]
    end

    cleaned
  end

  def extract_ruby_code(raw)
    raw.gsub(/```ruby\s*/i, '').gsub(/```/, '').strip
  end

  def save_page_file(code, nome_page, output_dir)
    FileUtils.mkdir_p(output_dir)

    file_name = nome_page
                .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                .downcase
                .concat('.rb')

    file_path = File.join(output_dir, file_name)
    File.write(file_path, code)

    puts "[Helper] Arquivo gerado: #{file_path}"
    file_path
  end
end
