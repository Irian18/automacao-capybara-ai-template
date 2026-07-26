# frozen_string_literal: true

require_relative 'base'

module SelfHealing
  module Tools
    class PageObjectCall < Base
      def definition
        {
          name: 'page_object_call',
          description: 'Invoca um elemento mapeado na SitePrism page object atual. ' \
                        'PREFIRA quando o elemento estiver mapeado.',
          parameters: {
            type: 'object',
            properties: {
              element: { type: 'string' },
              action: { type: 'string', enum: %w[click set text visible?] },
              value: { type: 'string' }
            },
            required: %w[element action]
          }
        }
      end

      def execute(input)
        with_retry do
          raise ArgumentError, 'Sem page object no contexto' unless page_object

          element = page_object.send(input['element'])
          case input['action']
          when 'click'    then element.click
          when 'set'      then element.set(input['value'])
          when 'text'     then element.text
          when 'visible?' then element.visible?.to_s
          end
        end
        'OK'
      end
    end
  end
end
