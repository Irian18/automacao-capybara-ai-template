require_relative 'api_client'
require_relative 'config'
require_relative 'snapshot'

module SelfHealing
  class LocatorHealer
    MAX_HEAL_ATTEMPTS = 2

    def initialize(session:)
      @session = session
      @client = ApiClient.new(model: Config.agent_model)
    end

    def heal(selector)
      attempts = 0
      loop do
        attempts += 1
        new_selector = try_heal(selector)
        return new_selector if new_selector

        raise Capybara::ElementNotFound, "Não foi possível curar o selector: #{selector}" if attempts >= MAX_HEAL_ATTEMPTS
      end
    end

    private

    def try_heal(selector)
      snapshot = Snapshot.new(@session).build
      prompt = build_prompt(selector, snapshot)

      response = @client.complete(prompt, system_content: system_prompt, max_tokens: 1024)
      new_selector = parse_selector(response)

      return nil if new_selector.nil? || new_selector == selector

      @session.find(new_selector)
      new_selector
    rescue Capybara::ElementNotFound
      nil
    end

    def build_prompt(selector, snapshot)
      <<~PROMPT
        Você é um assistente de automação de testes. Um selector CSS quebrado não foi encontrado na página atual.

        Selector quebrado: "#{selector}"

        Analise o snapshot da página abaixo e retorne APENAS o novo selector CSS mais confiável que corresponda ao mesmo elemento semântico.
        Prefira atributos estáveis como data-testid, data-test-id, id estável, name, aria-label.
        Não inclua explicações. Retorne apenas o selector em uma única linha.
        Se não encontrar correspondência, retorne EXATAMENTE: NOT_FOUND

        Snapshot da página:
        #{snapshot}
      PROMPT
    end

    def system_prompt
      'Você retorna apenas selectors CSS válidos ou NOT_FOUND. Não adicione comentários, markdown ou explicações.'
    end

    def parse_selector(response)
      return nil if response.nil?

      selector = response.strip
      return nil if selector.empty?
      return nil if selector.upcase.include?('NOT_FOUND')

      selector
    end
  end
end
