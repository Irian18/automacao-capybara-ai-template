require_relative 'tools/context'
require_relative 'tools/registry'

module SelfHealing
  module Tools
    def self.definitions(session:, page_object: nil, helper: nil)
      registry_for(session:, page_object:, helper:).definitions
    end

    def self.dispatch(name:, input:, session:, page_object: nil, helper: nil)
      registry_for(session:, page_object:, helper:).dispatch(name:, input:)
    end

    def self.recordable?(name:, session:, page_object: nil, helper: nil)
      registry_for(session:, page_object:, helper:).recordable?(name)
    end

    def self.registry_for(session:, page_object:, helper:)
      context = Context.new(session:, page_object:, helper:)
      Registry.new(context)
    end
    private_class_method :registry_for
  end

  class TestFailed < StandardError; end
end
