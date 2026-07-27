# frozen_string_literal: true

require 'yaml'
require_relative 'config'

module SelfHealing
  # Carrega configuração de design system para identificar seletores,
  # IDs instáveis e componentes customizados da aplicação.
  class DesignSystem
    DEFAULTS = {
      'interactive_selectors' => [
        'a', 'button', 'input', 'select', 'textarea',
        '[role="button"]', '[role="link"]',
        '[data-testid]', '[data-test-id]'
      ],
      'field_components' => {},
      'section_components' => %w[table modal dialog alert],
      'ignore_tags' => %w[script style meta link noscript template],
      'unstable_id_patterns' => [
        '\Acdk-', '\Amat-', '\Ack-', '\Aswal2-',
        '\A[a-z0-9]{20,}\z', '-\d{6,}\z',
        '\Aoption-\d+', '\Amodal-[a-f0-9]+', '\Adropdown-\d+'
      ],
      'noisy_class_prefixes' => %w[ng-tns- ng-trigger- cdk- mat-],
      'noisy_attr_prefixes' => %w[_ngcontent- _nghost-],
      'generated_classes' => %w[
        ng-untouched ng-touched ng-pristine ng-dirty
        ng-valid ng-invalid ng-pending ng-star-inserted
      ]
    }.freeze

    def self.load
      new(Config.design_system)
    end

    def initialize(path)
      @path = path
      @data = read_file
    end

    def interactive_selectors
      @data.fetch('interactive_selectors', DEFAULTS['interactive_selectors'])
    end

    def interactive_selector_string
      interactive_selectors.join(', ')
    end

    def field_components
      @data.fetch('field_components', DEFAULTS['field_components'])
    end

    def section_components
      @data.fetch('section_components', DEFAULTS['section_components'])
    end

    def ignore_tags
      @data.fetch('ignore_tags', DEFAULTS['ignore_tags'])
    end

    def ignore_tags_selector
      ignore_tags.join(', ')
    end

    def unstable_id_patterns
      patterns = @data.fetch('unstable_id_patterns', DEFAULTS['unstable_id_patterns'])
      patterns.map { |p| Regexp.new(p) }
    end

    def noisy_class_prefixes
      @data.fetch('noisy_class_prefixes', DEFAULTS['noisy_class_prefixes'])
    end

    def noisy_attr_prefixes
      @data.fetch('noisy_attr_prefixes', DEFAULTS['noisy_attr_prefixes'])
    end

    def generated_classes
      @data.fetch('generated_classes', DEFAULTS['generated_classes'])
    end

    private

    def read_file
      return DEFAULTS unless @path && File.exist?(@path)

      YAML.safe_load(File.read(@path), permitted_classes: [], aliases: true) || DEFAULTS
    rescue Psych::SyntaxError => e
      warn "[SelfHealing] Erro de sintaxe no design system config #{@path}: #{e.message}. Usando defaults."
      DEFAULTS
    end
  end
end
