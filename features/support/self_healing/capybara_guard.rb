require 'capybara'
require_relative 'locator_healer'
require_relative 'locator_history'
require_relative 'locator_applier'

module SelfHealing
  module CapybaraGuard
    HEALABLE_ERRORS = [
      Capybara::ElementNotFound,
      (defined?(Selenium::WebDriver::Error::NoSuchElementError) ? Selenium::WebDriver::Error::NoSuchElementError : nil),
      (defined?(Ferrum::NodeNotFoundError) ? Ferrum::NodeNotFoundError : nil)
    ].compact.freeze

    def find(*args, **options, &block)
      super
    rescue *HEALABLE_ERRORS => e
      raise e unless auto_correction_enabled?

      selector = extract_selector(args)
      raise e if selector.nil? || selector.empty?

      attempt_heal_and_retry(selector, options, block, e)
    end

    private

    def auto_correction_enabled?
      ENV['AUTO_CORRECTION_ENABLED'] == 'true'
    end

    def extract_selector(args)
      case args.size
      when 1
        args.first.is_a?(String) ? args.first : nil
      when 2
        args.first == :css ? args[1].to_s : nil
      else
        nil
      end
    end

    def attempt_heal_and_retry(selector, options, block, original_error)
      healer = LocatorHealer.new(session: self)
      new_selector = healer.heal(selector)

      raise original_error if new_selector.nil? || new_selector == selector

      record_and_apply(selector, new_selector)
      find(new_selector, **options, &block)
    rescue Capybara::ElementNotFound
      raise original_error
    end

    def record_and_apply(old_selector, new_selector)
      LocatorHistory.new.record(
        page_object: 'auto_healed',
        element_name: element_name_from_selector(old_selector),
        version: 1,
        locator: old_selector,
        reason: "Selector não encontrado durante execução",
        change_type: 'heal'
      )

      LocatorHistory.new.record(
        page_object: 'auto_healed',
        element_name: element_name_from_selector(old_selector),
        version: 2,
        locator: new_selector,
        reason: "Novo selector sugerido pela IA",
        change_type: 'heal'
      )

      LocatorApplier.new.apply_by_selector(
        old_selector: old_selector,
        new_selector: new_selector
      )
    rescue StandardError => e
      warn "[SelfHealing::CapybaraGuard] Falha ao registrar/aplicar correção: #{e.class}: #{e.message}"
    end

    def element_name_from_selector(selector)
      selector[/[a-zA-Z_][a-zA-Z0-9_]+/] || selector
    end
  end
end

Capybara::Session.prepend(SelfHealing::CapybaraGuard)
