require 'openai'
require_relative 'config'

module SelfHealing
  class ApiClient
    DEFAULT_MAX_RETRIES = 3
    DEFAULT_TIMEOUT = 60

    def initialize(model:, api_key: Config.api_key, base_url: Config.base_url)
      @model = model
      @client = OpenAI::Client.new(
        access_token: api_key,
        uri_base: base_url,
        log_errors: true,
        request_timeout: DEFAULT_TIMEOUT
      )
    end

    def chat(messages:, tools: nil, tool_choice: nil, temperature: 1, max_tokens: nil, system: nil, mode: nil)
      params = {
        model: @model,
        messages:,
        temperature:
      }
      params[:tools]       = tools       if tools
      params[:tool_choice] = tool_choice if tool_choice
      params[:max_tokens]  = max_tokens  if max_tokens
      params[:system]      = system      if system

      with_retry do
        @client.chat(parameters: params)
      end
    end

    def complete(prompt, system_content: nil, max_tokens: 4096, temperature: 1)
      messages = [{ role: 'user', content: prompt }]
      log_request('complete')

      response = chat(
        messages:,
        max_tokens:,
        temperature:,
        system: system_content
      )

      log_response(response)
      extract_content(response)
    end

    private

    def with_retry(max_attempts: DEFAULT_MAX_RETRIES)
      attempt = 0
      begin
        attempt += 1
        yield
      rescue Faraday::Error, OpenAI::Error => e
        raise e if attempt >= max_attempts

        wait = 2**attempt
        warn "[SelfHealing::ApiClient] Retry ##{attempt}/#{max_attempts} em #{wait}s — #{e.class}: #{e.message}"
        sleep(wait)
        retry
      end
    end

    def extract_content(response)
      message = response.dig('choices', 0, 'message')
      raise '[SelfHealing::ApiClient] Resposta da API não contém choices/message.' unless message

      content   = message['content']
      reasoning = message['reasoning_content']

      if blank?(content) && present?(reasoning)
        warn '[SelfHealing::ApiClient] Usando reasoning_content como fallback...'
        return reasoning
      end

      raise '[SelfHealing::ApiClient] API retornou content e reasoning_content vazios.' if blank?(content)

      content
    end

    def log_request(type)
      puts "[SelfHealing::ApiClient] Enviando requisição #{type} para modelo #{@model}..."
    end

    def log_response(response)
      message = response.dig('choices', 0, 'message')
      return unless message

      content   = message['content']
      reasoning = message['reasoning_content']
      puts "[SelfHealing::ApiClient] content: #{content.to_s.length} chars | reasoning_content: #{reasoning.to_s.length} chars"
    end

    def blank?(value)
      value.nil? || value.to_s.strip.empty?
    end

    def present?(value)
      !blank?(value)
    end
  end
end
