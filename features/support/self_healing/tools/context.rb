# frozen_string_literal: true

module SelfHealing
  module Tools
    # Contexto compartilhado entre as ferramentas do agente.
    Context = Struct.new(:session, :page_object, :helper, keyword_init: true)
  end
end
