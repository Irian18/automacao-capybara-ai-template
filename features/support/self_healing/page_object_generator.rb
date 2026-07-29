require 'fileutils'
require_relative 'api_client'
require_relative 'config'
require_relative 'prompt_loader'
require_relative 'rag'

module SelfHealing
  class PageObjectGenerator
    DEFAULT_OUTPUT_DIR = 'tmp/page_objects/generated'

    def initialize(session:, model: Config.po_model, output_dir: DEFAULT_OUTPUT_DIR, client: nil)
      @session    = session
      @model      = model
      @output_dir = output_dir
      @client     = client
    end

    def generate(page_name, url: nil, output_dir: nil)
      target_dir = output_dir || @output_dir
      FileUtils.mkdir_p(target_dir)

      html = @session.html.to_s
      page_url = url || safe_current_path

      prompt = PromptLoader.render('siteprism_generator',
                                   nome_page: page_name,
                                   url: page_url,
                                   html:,
                                   rag_context: rag_context_for(page_name))

      puts "[SelfHealing::PageObjectGenerator] Gerando PO #{page_name} com #{@model}..."
      raw = client.complete(prompt, max_tokens: 8192, temperature: 0.5)

      code = extract_ruby_code(raw)
      file_path = File.join(target_dir, "#{snake(page_name)}.rb")
      File.write(file_path, code)

      puts "[SelfHealing::PageObjectGenerator] PO salvo em #{file_path}"
      file_path
    end

    private

    def client
      @client ||= ApiClient.new(model: @model)
    end

    def safe_current_path
      @session.respond_to?(:current_path) ? @session.current_path : '/'
    rescue StandardError
      '/'
    end

    def extract_ruby_code(raw)
      text = raw.to_s

      if text =~ /```ruby\s*(.*?)\s*```/m
        code = Regexp.last_match(1).strip
        return code unless code.empty?
      end

      text.scan(/```\s*(.*?)\s*```/m).each do |match|
        candidate = match[0].to_s.strip
        return candidate if looks_like_ruby?(candidate)
      end

      return text.strip if looks_like_ruby?(text)

      "# Código gerado não parece Ruby válido. Resposta bruta:\n# #{text.strip.gsub("\n", "\n# ")}"
    end

    def looks_like_ruby?(text)
      return false if text.nil? || text.strip.empty?

      stripped = text.strip
      indicators = %w[class module element section def end set_url include extend require]
      indicators.any? { |token| stripped.match?(/\b#{token}\b/) }
    end

    def rag_context_for(page_name)
      return '' unless Config.rag_enabled?

      Rag::KnowledgeBase.new.index!
      retriever = Rag::Retriever.new
      retriever.context_for(
        "Page Object SitePrism para #{page_name}",
        label: 'PAGE OBJECTS DE REFERÊNCIA',
        filters: { 'type' => 'page_object' }
      )
    rescue StandardError => e
      warn "[SelfHealing::PageObjectGenerator] Falha ao recuperar contexto RAG: #{e.class}: #{e.message}"
      ''
    end

    def snake(string)
      return '' if string.nil?

      ascii = string.to_s.unicode_normalize(:nfkd).gsub(/\p{Mn}/, '')
      ascii
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .gsub(/[-\s]+/, '_')
        .gsub(/[^A-Za-z0-9_]/, '')
        .downcase
        .squeeze('_')
        .sub(/^_|_$/, '')
    end
  end
end
