require 'logger'
require_relative 'agent'
require_relative 'feature_reader'

module SelfHealing
  class TaggedScenarioRunner
    Result = Struct.new(:file, :line, :scenario, :step, :step_index, :success, :mode, :error, keyword_init: true)

    DEFAULT_FEATURES_DIR = 'features/specs/self_healing'.freeze

    def initialize(tag: nil, logger: Logger.new($stdout), **agent_options)
      @tag = tag
      @logger = logger
      @agent_options = agent_options
    end

    def run(features_dir: DEFAULT_FEATURES_DIR)
      reader = FeatureReader.new(features_dir: features_dir)
      scenarios = @tag ? reader.scenarios_with_tag(@tag) : reader.scenarios

      if scenarios.empty?
        @logger.info("[SelfHealing::TaggedScenarioRunner] Nenhum cenário encontrado em #{features_dir}#{@tag ? " com #{@tag}" : ''}")
        return []
      end

      @logger.info("[SelfHealing::TaggedScenarioRunner] #{scenarios.size} cenário(s) encontrado(s) em #{features_dir}#{@tag ? " com #{@tag}" : ''}")

      scenarios.flat_map { |scenario| run_scenario(scenario) }
    end

    private

    def run_scenario(scenario)
      @logger.info("[SelfHealing::TaggedScenarioRunner] Cenário: #{scenario.name} (#{scenario.file}:#{scenario.line})")
      agent = SelfHealing::Agent.new(logger: @logger, **@agent_options)

      scenario.steps.map.with_index do |step, idx|
        run_step(agent, scenario, step, idx)
      end
    end

    def run_step(agent, scenario, step, idx)
      @logger.info("[SelfHealing::TaggedScenarioRunner] Step ##{idx + 1}: #{step}")
      agent.execute(step)

      Result.new(
        file: scenario.file,
        line: scenario.line,
        scenario: scenario.name,
        step: step,
        step_index: idx,
        success: true,
        mode: agent.mode
      )
    rescue => e
      @logger.error("[SelfHealing::TaggedScenarioRunner] Step falhou: #{e.class}: #{e.message}")

      Result.new(
        file: scenario.file,
        line: scenario.line,
        scenario: scenario.name,
        step: step,
        step_index: idx,
        success: false,
        mode: agent.mode,
        error: e
      )
    end
  end
end
