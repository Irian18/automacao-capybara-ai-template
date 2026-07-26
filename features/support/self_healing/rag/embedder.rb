# frozen_string_literal: true

require 'openai'
require_relative '../config'

module SelfHealing
  module Rag
    class Embedder
      def embed(text)
        raise NotImplementedError
      end

      def self.default
        if Config.rag_embedding_model.to_s.strip.empty?
          KeywordEmbedder.new
        else
          ApiEmbedder.new
        end
      end
    end

    # Gera embeddings via API compatível com OpenAI.
    # Usa RAG_EMBEDDING_API_KEY / RAG_EMBEDDING_BASE_URL / RAG_EMBEDDING_MODEL.
    class ApiEmbedder < Embedder
      def initialize(
        api_key: Config.rag_embedding_api_key,
        base_url: Config.rag_embedding_base_url,
        model: Config.rag_embedding_model
      )
        @model = model
        @client = OpenAI::Client.new(
          access_token: api_key,
          uri_base: base_url,
          log_errors: false
        )
      end

      def embed(text)
        response = @client.embeddings(
          parameters: {
            model: @model,
            input: truncate(text, 8000)
          }
        )

        response.dig('data', 0, 'embedding')
      rescue StandardError => e
        warn "[SelfHealing::Rag::ApiEmbedder] Falha ao gerar embedding: #{e.class}: #{e.message}. Fallback para keyword."
        KeywordEmbedder.new.embed(text)
      end

      private

      def truncate(text, max_chars)
        text.to_s[0, max_chars]
      end
    end

    # Fallback sem custo de API: vetor de frequência de termos normalizado.
    # Útil para testes locais ou quando o modelo de embedding não está disponível.
    class KeywordEmbedder < Embedder
      DIMENSIONS = 256

      def embed(text)
        tokens = tokenize(text.to_s)
        vector = Array.new(DIMENSIONS, 0.0)

        tokens.each do |token|
          idx = token.hash.abs % DIMENSIONS
          vector[idx] += 1.0
        end

        normalize(vector)
      end

      private

      def tokenize(text)
        text.downcase.gsub(/[^\p{L}\p{N}\s]/, ' ').split.reject { |t| t.length < 2 }
      end

      def normalize(vector)
        magnitude = Math.sqrt(vector.sum { |v| v * v })
        return vector if magnitude.zero?

        vector.map { |v| v / magnitude }
      end
    end
  end
end
