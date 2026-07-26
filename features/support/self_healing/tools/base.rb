# frozen_string_literal: true

require 'capybara'
require 'ferrum'

module SelfHealing
  module Tools
    # Classe base para todas as ferramentas do agente.
    # Cada tool deve implementar #definition e #execute.
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

      # Descrição da tool no formato OpenAI.
      def definition
        raise NotImplementedError
      end

      # Executa a tool e retorna uma string como resultado.
      def execute(input)
        raise NotImplementedError
      end

      # Indica se esta tool deve ser gravada no plano cacheado.
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
