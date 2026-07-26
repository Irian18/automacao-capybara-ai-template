# frozen_string_literal: true

require_relative 'base'

module SelfHealing
  module Tools
    class AssertText < Base
      WAIT_SECONDS = 10

      def definition
        {
          name: 'assert_text',
          description: 'Verifica se um texto está visível na página.',
          parameters: {
            type: 'object',
            properties: { text: { type: 'string' } },
            required: ['text']
          }
        }
      end

      def execute(input)
        text = input['text']
        session.assert_text(text, wait: WAIT_SECONDS)
        'PRESENTE'
      rescue Capybara::ExpectationNotMet
        "AUSENTE: texto '#{text}' não apareceu dentro de #{WAIT_SECONDS}s"
      end
    end
  end
end
