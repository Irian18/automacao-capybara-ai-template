# frozen_string_literal: true

require_relative 'base'

module SelfHealing
  module Tools
    class FillIn < Base
      def definition
        {
          name: 'fill_in',
          description: 'Preenche um campo de texto, textarea ou qualquer input. ' \
                        'Aceita id, name, formcontrolname, label, placeholder ou seletor CSS.',
          parameters: {
            type: 'object',
            properties: {
              field: { type: 'string', description: 'id, name, formcontrolname, label, placeholder ou seletor CSS' },
              value: { type: 'string' }
            },
            required: %w[field value]
          }
        }
      end

      def execute(input)
        with_retry do
          session.fill_in(input['field'], with: input['value'])
        rescue Capybara::ElementNotFound
          el = session.find(input['field'], wait: 5)
          el.set(input['value'])
        end
        'OK'
      end
    end
  end
end
