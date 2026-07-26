# frozen_string_literal: true

module SelfHealing
  # Contexto de execução compartilhado entre os componentes do agente.
  AgentContext = Struct.new(:session, :page_object, :helper, :logger, keyword_init: true) do
    def client
      @client ||= ApiClient.new(model: Config.agent_model)
    end

    def cache
      @cache ||= PlanCache.new
    end
  end
end
