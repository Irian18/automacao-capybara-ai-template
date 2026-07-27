# frozen_string_literal: true

require_relative 'base'

module SelfHealing
  module Tools
    class FailTest < Base
      def definition
        {
          name: 'fail_test',
          description: 'Marca a tarefa como impossível de executar.',
          parameters: {
            type: 'object',
            properties: { reason: { type: 'string' } },
            required: ['reason']
          }
        }
      end

      def execute(input)
        raise SelfHealing::TestFailed, input['reason']
      end

      def recordable?
        false
      end
    end
  end
end
