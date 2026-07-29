require 'logger'
require 'json'
require_relative 'config'
require_relative 'api_client'
require_relative 'agent_context'
require_relative 'conversation'
require_relative 'prompt_loader'
require_relative 'plan_executor'
require_relative 'snapshot'
require_relative 'rag'
require_relative 'locator_history'

module SelfHealing
  class Agent
    MAX_ITERATIONS = 15

    attr_reader :mode # :replay, :record, :heal

    def initialize(session: Capybara.current_session, page_object: nil, logger: Logger.new($stdout), cache: nil,
                   helper: nil, rag: nil)
      validate_config!

      @context = AgentContext.new(
        session:,
        page_object:,
        helper:,
        logger:
      )
      @context.cache = cache if cache

      @rag = rag || build_default_rag
      @rag_context_cache = {}
      @conversation = Conversation.new
      @recorded_steps = []
    end

    def execute(instruction)
      @instruction = instruction
      @context.cache.delete(instruction) if ENV['AI_FORCE_RECORD'] == 'true'

      if @context.cache.exists?(instruction)
        replay_or_heal(instruction)
      else
        record(instruction)
      end
    rescue SelfHealing::TestFailed
      invalidate_cache_on_failure!(instruction)
      raise
    end

    private

    def replay_or_heal(instruction)
      @mode = :replay
      plan = @context.cache.load(instruction)

      unless plan
        @context.logger.info('[SelfHealing] Cache inválido/inexistente, indo para RECORD')
        return record(instruction)
      end

      log_replay(plan)

      executor = PlanExecutor.new(
        session: @context.session,
        page_object: @context.page_object,
        logger: @context.logger,
        helper: @context.helper
      )
      result = executor.execute(plan)

      return "REPLAY_OK: #{instruction}" if result.success

      heal(instruction, plan, result)
    end

    def heal(instruction, plan, failure_result)
      @mode = :heal
      @context.logger.warn("[SelfHealing] Modo HEAL — passo ##{failure_result.step_index} falhou (#{failure_result.error.message})")

      successful_steps = plan.steps[0...failure_result.step_index]
      failed_step      = failure_result.step
      remaining_steps  = plan.steps[(failure_result.step_index + 1)..]

      heal_content = PromptLoader.render('heal',
                                         instruction:,
                                         successful_steps: format_steps(successful_steps),
                                         failed_step_json: failed_step.to_json,
                                         error_class: failure_result.error.class.to_s,
                                         error_message: failure_result.error.message,
                                         remaining_steps: format_steps(remaining_steps),
                                         rag_context: rag_context_for(instruction))

      @recorded_steps = successful_steps.dup
      @conversation.clear
      @conversation.user(heal_content)

      finish_summary = run_agentic_loop(mode: :heal)
      heal_reason = extract_heal_reason(finish_summary)

      new_plan = Plan.new(
        instruction:,
        steps: @recorded_steps,
        version: (plan.version + 1),
        heal_reason:
      )
      @context.cache.save(new_plan)
      record_locator_changes!(plan, new_plan)

      @context.logger.info("[SelfHealing] Cache atualizado (versão #{plan.version + 1})#{heal_reason ? " — motivo: #{heal_reason}" : ''}")

      "HEAL_OK: #{instruction}"
    end

    def record(instruction)
      @mode = :record
      @context.logger.info("[SelfHealing] Modo RECORD — descobrindo plano para: #{instruction}")

      snapshot = Snapshot.new(@context.session).build
      persist_snapshot(snapshot)

      @recorded_steps = []
      @conversation.clear
      @conversation.system(system_prompt)
      @conversation.user(user_message_with_rag(instruction))

      result = run_agentic_loop(mode: :record)
      @context.cache.save(Plan.new(instruction:, steps: @recorded_steps, version: 1))
      @context.logger.info("[SelfHealing] Plano salvo com #{@recorded_steps.size} passos")

      "RECORD_OK: #{result}"
    end

    def run_agentic_loop(mode:)
      MAX_ITERATIONS.times do
        response = @context.client.chat(
          messages: @conversation.messages,
          tools: tool_definitions,
          tool_choice: 'auto',
          temperature: 1,
          mode:
        )

        message    = response.dig('choices', 0, 'message')
        tool_calls = message['tool_calls'] || []

        @conversation.assistant(message, tool_calls:)

        return message['content'] if tool_calls.empty?

        tool_calls.each do |tc|
          name = tc.dig('function', 'name')
          args = JSON.parse(tc.dig('function', 'arguments') || '{}')
          @context.logger.info("[SelfHealing] Tool call: #{name}(#{args.to_json})")

          tool_result = run_tool(name, args)
          @recorded_steps << { 'name' => name, 'input' => args } if recordable_tool?(name)

          @conversation.tool(
            tool_call_id: tc['id'],
            name:,
            content: tool_result
          )

          return tool_result if name == 'finish'
          raise SelfHealing::TestFailed, args['reason'] if name == 'fail_test'
        end
      end

      raise "AI Agent atingiu o limite de #{MAX_ITERATIONS} iterações"
    end

    def recordable_tool?(tool_name)
      SelfHealing::Tools.recordable?(
        name: tool_name,
        session: @context.session,
        page_object: @context.page_object,
        helper: @context.helper
      )
    end

    def tool_definitions
      SelfHealing::Tools.definitions(
        session: @context.session,
        page_object: @context.page_object,
        helper: @context.helper
      )
    end

    def run_tool(name, input)
      SelfHealing::Tools.dispatch(
        name:,
        input:,
        session: @context.session,
        page_object: @context.page_object,
        helper: @context.helper
      )
    rescue SelfHealing::TestFailed
      raise
    rescue StandardError => e
      "ERRO: #{e.class}: #{e.message}"
    end

    def extract_heal_reason(finish_summary)
      return nil unless finish_summary.is_a?(String)

      match = finish_summary.match(/FINISHED:\s*(.+)/)
      match ? match[1].strip : finish_summary.strip[0, 200]
    end

    def format_steps(steps)
      return '(nenhum)' if steps.nil? || steps.empty?

      steps.each_with_index.map { |s, i| "  #{i + 1}. #{s['name']}(#{s['input'].to_json})" }.join("\n")
    end

    def record_locator_changes!(old_plan, new_plan)
      page_object_name = @context.page_object.class.name if @context.page_object

      old_steps = old_plan.steps || []
      new_steps = new_plan.steps || []

      [old_steps.size, new_steps.size].min.times do |i|
        old_step = old_steps[i]
        new_step = new_steps[i]

        next unless old_step['name'] == new_step['name']

        old_input = old_step['input'] || {}
        new_input = new_step['input'] || {}

        old_locator = extract_locator(old_step['name'], old_input)
        new_locator = extract_locator(new_step['name'], new_input)

        next if old_locator.nil? || new_locator.nil? || old_locator == new_locator

        element_name = element_name_from_step(new_step['name'], new_input) || 'unknown'

        @context.locator_history.record(
          page_object: page_object_name || 'unknown',
          element_name: element_name,
          version: old_plan.version,
          locator: old_locator,
          reason: new_plan.heal_reason,
          change_type: 'heal'
        )

        @context.locator_history.record(
          page_object: page_object_name || 'unknown',
          element_name: element_name,
          version: new_plan.version,
          locator: new_locator,
          reason: new_plan.heal_reason,
          change_type: 'heal'
        )
      end
    rescue StandardError => e
      @context.logger.warn("[SelfHealing] Falha ao registrar histórico de locators: #{e.class}: #{e.message}")
    end

    def extract_locator(tool_name, input)
      case tool_name
      when 'click'    then input['css']
      when 'fill_in'  then input['field']
      when 'assert_element' then input['css']
      when 'page_object_call' then input['element']
      else input['css'] || input['field'] || input['element'] || input['selector']
      end
    end

    def element_name_from_step(tool_name, input)
      case tool_name
      when 'page_object_call' then input['element']
      else input['element'] || extract_locator(tool_name, input)
      end
    end

    def system_prompt
      PromptLoader.render('system',
                          page_object_context:,
                          rag_context: rag_context_for(@instruction))
    end

    def user_message_with_rag(instruction)
      rag = rag_context_for(instruction)
      rag.empty? ? instruction : "#{instruction}\n\n#{rag}"
    end

    def rag_context_for(instruction)
      return '' if instruction.nil? || instruction.strip.empty?
      return '' unless @rag

      @rag_context_cache[instruction] ||= begin
        context = @rag.context_for(instruction)
        doc_count = context.to_s.scan(/\[score:/).size
        @context.logger.info("[SelfHealing] RAG recuperou #{doc_count} documentos para instrução")
        context
      end
    rescue StandardError => e
      @context.logger.warn("[SelfHealing] Falha ao recuperar contexto RAG: #{e.class}: #{e.message}")
      ''
    end

    def build_default_rag
      return nil unless Config.rag_enabled?

      Rag::KnowledgeBase.new.index!
      Rag::Retriever.new
    end

    def page_object_context
      return '' unless @context.page_object.is_a?(SitePrism::Page)

      elements = @context.page_object.class.mapped_items[:element] || []
      sections = @context.page_object.class.mapped_items[:section] || []
      <<~CTX
        CONTEXTO DA PAGE OBJECT (#{@context.page_object.class.name}):
        Elementos mapeados: #{elements.map { |e| e[:name] }.join(', ')}
        Seções mapeadas: #{sections.map { |s| s[:name] }.join(', ')}

        Você pode usar `page_object_call` para invocar esses elementos diretamente — PREFIRA isso.
      CTX
    end

    def persist_snapshot(snapshot)
      File.write('tmp/self_healing_snapshot.json', snapshot)
      @context.logger.info("[SelfHealing] Snapshot salvo em tmp/self_healing_snapshot.json (#{snapshot.length} chars)")
    end

    def log_replay(plan)
      msg = "[SelfHealing] Modo REPLAY (#{plan.steps.size} passos, v#{plan.version}, " \
            "atualizado em #{plan.updated_at})"
      @context.logger.info(msg)
    end

    def invalidate_cache_on_failure!(instruction)
      return unless @mode == :heal

      @context.logger.warn('[SelfHealing] HEAL falhou — invalidando cache para instrução')
      @context.cache.delete(instruction)
    end

    def validate_config!
      Config.api_key
    rescue KeyError
      raise '[SelfHealing] AI_API_KEY não definida. Configure no arquivo .env.'
    end
  end
end
