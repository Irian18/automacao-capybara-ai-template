module SelfHealing
  class PlanExecutor
    StepResult = Struct.new(:success, :step_index, :step, :error, :tool_result, keyword_init: true)

    def initialize(session:, page_object: nil, logger:, helper: nil)
      @session     = session
      @page_object = page_object
      @helper      = helper
      @logger      = logger
    end

    def execute(plan)
      plan.steps.each_with_index do |step, idx|
        result = execute_step(step, idx)
        return result unless result.success
      end

      StepResult.new(success: true, step_index: nil, step: nil, error: nil)
    end

    private

    def execute_step(step, idx)
      name  = step['name']
      input = step['input'] || {}

      @logger.info("[REPLAY ##{idx}] #{name}(#{input.to_json})")

      tool_result = SelfHealing::Tools.dispatch(
        name: name,
        input: input,
        session: @session,
        page_object: @page_object,
        helper: @helper
      )

      StepResult.new(success: true, step_index: idx, step: step, tool_result: tool_result)
    rescue SelfHealing::TestFailed
      raise
    rescue StandardError => e
      @logger.warn("[REPLAY ##{idx}] FALHOU: #{e.class}: #{e.message}")
      StepResult.new(success: false, step_index: idx, step: step, error: e)
    end
  end
end
