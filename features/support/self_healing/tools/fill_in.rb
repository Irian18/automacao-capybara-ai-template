require_relative 'base'

module SelfHealing
  module Tools
    class FillIn < Base
      def definition
        {
          name: 'fill_in',
          description: 'Preenche um campo de texto, textarea ou qualquer input. ' \
                        'Aceita id, data-test, data-teste-id,name, formcontrolname, label, placeholder ou seletor CSS.',
          parameters: {
            type: 'object',
            properties: {
              field: { type: 'string', description: 'id, data-test, data-teste-id, name, formcontrolname, label, placeholder ou seletor CSS' },
              value: { type: 'string' }
            },
            required: %w[field value]
          }
        }
      end

      def execute(input)
        with_retry do
          el = session.find(input['field'], wait: 3)
          el.set(input['value'])
        end
        'OK'
      end
    end
  end
end
