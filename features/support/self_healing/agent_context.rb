require_relative 'locator_history'

module SelfHealing
  AgentContext = Struct.new(:session, :page_object, :helper, :logger, keyword_init: true) do
    def client
      @client ||= ApiClient.new(model: Config.agent_model)
    end

    def cache
      @cache ||= PlanCache.new
    end

    def locator_history
      @locator_history ||= LocatorHistory.new
    end
  end
end
