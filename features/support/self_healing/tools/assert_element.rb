# frozen_string_literal: true

require_relative 'base'

module SelfHealing
  module Tools
    class AssertElement < Base
      WAIT_SECONDS = 5

      def definition
        {
          name: 'assert_element',
          description: 'Verifica se um elemento está presente/visível na página via CSS.',
          parameters: {
            type: 'object',
            properties: {
              css: { type: 'string', description: 'Seletor CSS' },
              visible: { type: 'boolean', description: 'Se true, exige visibilidade' }
            },
            required: ['css']
          }
        }
      end

      def execute(input)
        css = input['css']
        visible = input.fetch('visible', true)
        opts = visible ? { visible: true } : {}
        session.find(css, **opts, wait: WAIT_SECONDS)
        'ELEMENTO_PRESENTE'
      rescue Capybara::ElementNotFound
        'ELEMENTO_AUSENTE'
      end
    end
  end
end
