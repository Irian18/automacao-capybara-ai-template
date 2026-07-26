# frozen_string_literal: true

module SelfHealing
  # Lê arquivos .feature e extrai cenários, tags e steps.
  class FeatureReader
    DEFAULT_STEP_KEYWORDS = %w[
      Given When Then And But *
      Dado Dada Dados Dadas Quando Então Entao E Mas
    ].freeze

    Scenario = Struct.new(:file, :line, :name, :steps, :tags, keyword_init: true)

    def initialize(features_dir: 'features', step_keywords: DEFAULT_STEP_KEYWORDS)
      @features_dir = features_dir
      @step_keywords = step_keywords
    end

    def scenarios
      feature_files.flat_map { |file| parse_file(file) }
    end

    def scenarios_with_tag(tag)
      target = normalize_tag(tag)
      scenarios.select { |s| s.tags.include?(target) }
    end

    private

    def feature_files
      Dir.glob(File.join(@features_dir, '**', '*.feature')).sort
    end

    def parse_file(file)
      scenarios = []
      pending_tags = []
      feature_tags = []
      current_scenario = nil

      File.readlines(file).each_with_index do |raw_line, idx|
        line_number = idx + 1
        line = raw_line.strip

        next if skip_line?(line)

        if line.start_with?('@')
          pending_tags = extract_tags(line)
        elsif line.start_with?('Feature:')
          feature_tags = pending_tags
          pending_tags = []
          current_scenario = nil
        elsif (match = line.match(/\A(Scenario|Scenario Outline|Cenário|Cenario|Esquema do Cenário):\s*(.*)\z/))
          current_scenario = build_scenario(file, line_number, match[2], feature_tags, pending_tags)
          scenarios << current_scenario
          pending_tags = []
        elsif current_scenario && step?(line)
          current_scenario.steps << line
        end
      end

      scenarios
    end

    def skip_line?(line)
      line.empty? || line.start_with?('#')
    end

    def extract_tags(line)
      line.split(/\s+/).map { |t| normalize_tag(t) }
    end

    def build_scenario(file, line, name, feature_tags, scenario_tags)
      Scenario.new(
        file: file,
        line: line,
        name: name.strip,
        steps: [],
        tags: (feature_tags + scenario_tags).uniq
      )
    end

    def step?(line)
      first_word = line.split(/\s+/, 2).first.to_s
      @step_keywords.include?(first_word)
    end

    def normalize_tag(tag)
      tag = tag.to_s.strip
      tag.start_with?('@') ? tag : "@#{tag}"
    end
  end
end
