# frozen_string_literal: true

module SelfHealing
  # Configurações centralizadas do SelfHealing.
  # Todos os valores podem ser sobrescritos via variáveis de ambiente.
  # Os valores padrão estão documentados no .env.example.
  module Config
    class << self
      def api_key
        ENV.fetch('AI_API_KEY') do
          raise '[SelfHealing] AI_API_KEY não definida. Configure no arquivo .env.'
        end
      end

      def base_url
        ENV.fetch('BASE_URL', 'https://api.moonshot.ai/v1')
      end

      def agent_model
        ENV.fetch('MODEL', 'kimi-k2.6')
      end

      def po_model
        ENV.fetch('PO_MODEL', 'moonshot-v1-128k')
      end

      def design_system
        ENV.fetch('DESIGN_SYSTEM_CONFIG', File.expand_path('config/design_system.yml', __dir__))
      end

      def rag_enabled?
        ENV.fetch('RAG_ENABLED', 'false').downcase == 'true'
      end

      def rag_store_path
        ENV.fetch('RAG_STORE_PATH', File.expand_path('rag_store', __dir__))
      end

      def rag_knowledge_base_dir
        ENV.fetch('RAG_KNOWLEDGE_BASE_DIR', File.expand_path('knowledge_base', __dir__))
      end

      def rag_top_k
        ENV.fetch('RAG_TOP_K', '3').to_i
      end

      def rag_min_similarity
        ENV.fetch('RAG_MIN_SIMILARITY', '0.0').to_f
      end

      def rag_embedding_model
        ENV.fetch('RAG_EMBEDDING_MODEL', 'text-embedding-3-small')
      end

      def rag_embedding_api_key
        ENV.fetch('RAG_EMBEDDING_API_KEY', api_key)
      end

      def rag_embedding_base_url
        ENV.fetch('RAG_EMBEDDING_BASE_URL', base_url)
      end
    end
  end
end
