require 'capybara'
require 'ferrum'

module SelfHealing
  module Tools
    class Base
      RETRYABLE_ERRORS = [
        Capybara::ElementNotFound,
        Ferrum::NodeNotFoundError,
        Capybara::ExpectationNotMet
      ].freeze

      attr_reader :context

      def initialize(context)
        @context = context
      end

      def definition
        raise NotImplementedError
      end

      def execute(input)
        raise NotImplementedError
      end

      def recordable?
        true
      end

      protected

      def session
        @context.session
      end

      def page_object
        @context.page_object
      end

      def helper
        @context.helper
      end

      def with_retry(max_attempts: 3)
        attempt = 0
        begin
          attempt += 1
          yield
        rescue *RETRYABLE_ERRORS => e
          raise e if attempt >= max_attempts

          wait = 2**(attempt - 1)
          warn "[SelfHealing::Tools] Retry ##{attempt}/#{max_attempts} em #{wait}s — #{e.class}: #{e.message}"
          sleep(wait)
          retry
        end
      end
    end
  end
end
