# frozen_string_literal: true

require_relative 'base'

module SelfHealing
  module Tools
    class Visit < Base
      def definition
        {
          name: 'visit',
          description: 'Navega para uma URL.',
          parameters: {
            type: 'object',
            properties: { url: { type: 'string' } },
            required: ['url']
          }
        }
      end

      def execute(input)
        session.visit(input['url'])
        'OK'
      end
    end
  end
end
