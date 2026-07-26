# frozen_string_literal: true

require_relative 'base'

module SelfHealing
  module Tools
    class SelectOption < Base
      def definition
        {
          name: 'select_option',
          description: 'Seleciona uma opção de um <select> HTML nativo.',
          parameters: {
            type: 'object',
            properties: {
              option: { type: 'string', description: 'Texto ou valor da opção' },
              from: { type: 'string', description: 'Label, id ou name do select' }
            },
            required: %w[option from]
          }
        }
      end

      def execute(input)
        with_retry do
          session.select(input['option'], from: input['from'])
        end
        'OK'
      end
    end
  end
end
