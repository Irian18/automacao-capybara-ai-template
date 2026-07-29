require_relative 'base'
require_relative 'context'

module SelfHealing
  module Tools
    class Registry
      TOOL_CLASSES = %w[
        inspect_page
        visit
        click
        fill_in
        select_option
        assert_text
        assert_element
        page_object_call
        generate_page_object
        finish
        fail_test
      ].freeze

      def initialize(context)
        @context = context
        @tools = load_tools
      end

      def definitions
        @tools.values.map { |tool| { type: 'function', function: tool.definition } }
      end

      def dispatch(name:, input:)
        tool = @tools[name]
        raise ArgumentError, "Tool desconhecida: #{name}" unless tool

        tool.execute(input)
      end

      def recordable?(name)
        tool = @tools[name]
        return false unless tool

        tool.recordable?
      end

      private

      def load_tools
        TOOL_CLASSES.each_with_object({}) do |class_name, registry|
          require_relative class_name
          klass = tool_class_for(class_name)
          tool = klass.new(@context)
          registry[tool.definition[:name]] = tool
        end
      end

      def tool_class_for(file_name)
        SelfHealing::Tools.const_get(classify(file_name))
      end

      def classify(file_name)
        file_name.split('_').map(&:capitalize).join
      end
    end
  end
end
