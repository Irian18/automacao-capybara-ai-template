require_relative 'tools/context'
require_relative 'tools/registry'

module SelfHealing
  module Tools
    module_function

    def definitions(session:, page_object: nil, helper: nil)
      registry_for(session:, page_object:, helper:).definitions
    end

    def dispatch(name:, input:, session:, page_object: nil, helper: nil)
      registry_for(session:, page_object:, helper:).dispatch(name:, input:)
    end

    def recordable?(name:, session:, page_object: nil, helper: nil)
      registry_for(session:, page_object:, helper:).recordable?(name)
    end

    private

    def registry_for(session:, page_object:, helper:)
      context = Context.new(session:, page_object:, helper:)
      Registry.new(context)
    end
  end

  class TestFailed < StandardError; end
end
