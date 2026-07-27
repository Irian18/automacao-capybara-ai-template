# frozen_string_literal: true

require_relative 'base'
require_relative '../snapshot'

module SelfHealing
  module Tools
    class InspectPage < Base
      def definition
        {
          name: 'inspect_page',
          description: 'Retorna um snapshot estruturado dos elementos interativos visíveis na página atual.',
          parameters: { type: 'object', properties: {}, required: [] }
        }
      end

      def execute(_input)
        Snapshot.new(session).build
      end

      def recordable?
        false
      end
    end
  end
end
