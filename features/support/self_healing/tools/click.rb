require_relative 'base'

module SelfHealing
  module Tools
    class Click < Base
      def definition
        {
          name: 'click',
          description: 'Clica em um elemento. Use texto visível OU seletor CSS. ' \
                        'PREFIRA data-test-id/data-testid quando disponíveis.',
          parameters: {
            type: 'object',
            properties: {
              text: { type: 'string', description: 'Texto visível exato do elemento' },
              css: { type: 'string', description: 'Seletor CSS (ex: "[data-test-id=\"submit\"]", "#save")' }
            }
          }
        }
      end

      def execute(input)
        with_retry do
          if input['text']
            session.click_on(input['text'])
          else
            session.find(input['css']).click
          end
        end
        'OK'
      end
    end
  end
end
