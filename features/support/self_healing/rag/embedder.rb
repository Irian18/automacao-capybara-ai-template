# frozen_string_literal: true

require 'openai'
require_relative '../config'

module SelfHealing
  module Rag
    class Embedder
      def embed(_text, task: nil)
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

    class ApiEmbedder < Embedder
      def initialize(
        api_key: Config.rag_embedding_api_key,
        base_url: Config.rag_embedding_base_url,
        model: Config.rag_embedding_model,
        dimensions: Config.rag_embedding_dimensions
      )
        @model = model
        @dimensions = dimensions
        @client = OpenAI::Client.new(
          access_token: api_key,
          uri_base: base_url,
          log_errors: false
        )
      end

      def embed(text, task: nil)
        parameters = {
          model: @model,
          input: truncate(text, 8000)
        }
        parameters[:dimensions] = @dimensions if @dimensions
        parameters[:task] = task if task

        response = @client.embeddings(parameters:)

        response.dig('data', 0, 'embedding')
      rescue StandardError => e
        warn "[SelfHealing::Rag::ApiEmbedder] Embedding falhou: #{e.class}: #{e.message}. Fallback keyword."
        KeywordEmbedder.new.embed(text, task:)
      end

      private

      def truncate(text, max_chars)
        text.to_s[0, max_chars]
      end
    end

    class KeywordEmbedder < Embedder
      DIMENSIONS = 256

      def embed(text, **_kwargs)
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
