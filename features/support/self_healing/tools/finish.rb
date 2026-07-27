# frozen_string_literal: true

require_relative 'base'

module SelfHealing
  module Tools
    class Finish < Base
      def definition
        {
          name: 'finish',
          description: 'Marca a tarefa como concluída com sucesso.',
          parameters: {
            type: 'object',
            properties: { summary: { type: 'string' } },
            required: ['summary']
          }
        }
      end

      def execute(input)
        "FINISHED: #{input['summary']}"
      end

      def recordable?
        false
      end
    end
  end
end
