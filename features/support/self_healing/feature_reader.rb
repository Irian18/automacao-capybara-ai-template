# frozen_string_literal: true

module SelfHealing
  # Lê arquivos .feature (Gherkin) e extrai cenários, tags e steps.
  #
  # Responsabilidades:
  #   - Descobrir arquivos .feature recursivamente.
  #   - Parsear tags, Feature, Background, Scenario/Scenario Outline e steps.
  #   - Expor cenários como value objects imutáveis ({Scenario}).
  #
  # Padrões aplicados:
  #   - Single Responsibility: parsing isolado de busca/filtragem.
  #   - Value Object: Scenario encapsula dados de um cenário.
  #   - State Machine: a leitura do arquivo transita entre estados
  #     (fora de contexto, background, cenário).
  #   - Template Method / Strategy: cada tipo de linha é processado por método
  #     privado especializado, facilitando extensões futuras.
  class FeatureReader
    DEFAULT_STEP_KEYWORDS = %w[
      Given When Then And But *
      Dado Dada Dados Dadas Quando Então Entao E Mas
    ].freeze

    SCENARIO_PATTERN = /\A(?:Scenario|Scenario Outline|Cenário|Cenario|Esquema do Cenário):\s*(.*)\z/
    BACKGROUND_PATTERN = /\ABackground:|\ACenário de Fundo:|\AContexto:/
    FEATURE_PATTERN = /\AFeature:/

    Scenario = Struct.new(:file, :line, :name, :steps, :tags, keyword_init: true) do
      def initialize(file:, line:, name:, steps:, tags:)
        super(
          file:,
          line:,
          name:,
          steps: steps.dup.freeze,
          tags: tags.dup.freeze
        )
        freeze
      end
    end

    def initialize(features_dir: 'features', step_keywords: DEFAULT_STEP_KEYWORDS)
      @features_dir = features_dir
      @step_keywords = normalize_keywords(step_keywords)
    end

    # Retorna todos os cenários encontrados nos arquivos .feature.
    #
    # @return [Array<Scenario>]
    def scenarios
      feature_files.flat_map { |file| parse_file(file) }
    end

    # Retorna os cenários que possuem a tag informada.
    #
    # @param tag [String, Symbol]
    # @return [Array<Scenario>]
    def scenarios_with_tag(tag)
      target = normalize_tag(tag)
      scenarios.select { |s| s.tags.include?(target) }
    end

    private

    def feature_files
      Dir.glob(File.join(@features_dir, '**', '*.feature'))
    end

    def parse_file(file)
      state = initial_state(file)

      File.readlines(file, chomp: true, encoding: 'UTF-8').each_with_index do |raw_line, idx|
        process_line(raw_line.strip, idx + 1, state)
      end

      finalize(state)
    end

    def initial_state(file)
      {
        file:,
        scenarios: [],
        pending_tags: [],
        feature_tags: [],
        background_steps: [],
        context: :none,
        current: nil
      }
    end

    def process_line(line, line_number, state)
      return if skip_line?(line)

      if tag_line?(line)
        state[:pending_tags] = extract_tags(line)
      elsif feature_line?(line)
        reset_to_feature(state)
      elsif background_line?(line)
        reset_to_background(state)
      elsif (match = scenario_line?(line))
        start_scenario(state, line_number, match[1].strip)
      elsif step?(line)
        add_step(line, state)
      end
    end

    def reset_to_feature(state)
      state[:scenarios] << finalize_scenario(state[:current])
      state[:feature_tags] = state[:pending_tags]
      state[:pending_tags] = []
      state[:background_steps] = []
      state[:context] = :feature
      state[:current] = nil
    end

    def reset_to_background(state)
      state[:scenarios] << finalize_scenario(state[:current])
      state[:context] = :background
      state[:current] = nil
      state[:pending_tags] = []
    end

    def start_scenario(state, line_number, name)
      state[:scenarios] << finalize_scenario(state[:current])
      state[:current] = build_scenario_data(
        state[:file],
        line_number,
        name,
        state[:feature_tags],
        state[:pending_tags],
        state[:background_steps]
      )
      state[:context] = :scenario
      state[:pending_tags] = []
    end

    def add_step(line, state)
      case state[:context]
      when :scenario
        state[:current][:steps] << line
      when :background
        state[:background_steps] << line
      end
    end

    def finalize(state)
      state[:scenarios] << finalize_scenario(state[:current])
      state[:scenarios].compact
    end

    def build_scenario_data(file, line, name, feature_tags, scenario_tags, background_steps)
      {
        file:,
        line:,
        name:,
        steps: background_steps.dup,
        tags: (feature_tags + scenario_tags).uniq
      }
    end

    def finalize_scenario(data)
      return nil if data.nil?

      Scenario.new(**data)
    end

    def skip_line?(line)
      line.empty? || line.start_with?('#')
    end

    def tag_line?(line)
      line.start_with?('@')
    end

    def extract_tags(line)
      line.split(/\s+/).map { |t| normalize_tag(t) }
    end

    def feature_line?(line)
      FEATURE_PATTERN.match?(line)
    end

    def background_line?(line)
      BACKGROUND_PATTERN.match?(line)
    end

    def scenario_line?(line)
      line.match(SCENARIO_PATTERN)
    end

    def step?(line)
      first_word = line.split(/\s+/, 2).first.to_s
      @step_keywords.include?(first_word)
    end

    def normalize_tag(tag)
      tag = tag.to_s.strip
      tag.start_with?('@') ? tag : "@#{tag}"
    end

    def normalize_keywords(keywords)
      Array(keywords).map(&:to_s).freeze
    end
  end
end
