# frozen_string_literal: true

require_relative '../config'
require_relative 'store'
require_relative 'embedder'

module SelfHealing
  module Rag
    class Retriever
      Result = Struct.new(:document, :score, keyword_init: true)

      def initialize(
        store: Store.new,
        embedder: Embedder.default,
        top_k: Config.rag_top_k,
        min_similarity: Config.rag_min_similarity
      )
        @store = store
        @embedder = embedder
        @top_k = top_k
        @min_similarity = min_similarity
        @query_cache = {}
      end

      def search(query, filters: {})
        cache_key = cache_key_for(query, filters)
        return @query_cache[cache_key] if @query_cache.key?(cache_key)

        query_embedding = @embedder.embed(query, task: Config.rag_embedding_task_query)
        docs = @store.all

        scored = docs.map do |doc|
          score = cosine_similarity(query_embedding, doc.embedding)
          Result.new(document: doc, score:)
        end

        scored = scored.select { |r| r.score >= @min_similarity }
        scored = scored.sort_by { |r| -r.score }
        scored = scored.first(@top_k)
        scored = apply_filters(scored, filters)

        @query_cache[cache_key] = scored
      end

      def clear_cache
        @query_cache = {}
      end

      def search_text(query, filters: {})
        search(query, filters:).map do |result|
          format_result(result)
        end.join("\n\n---\n\n")
      end

      def context_for(query, label: 'CONTEXTO RECUPERADO', filters: {})
        text = search_text(query, filters:)
        return '' if text.strip.empty?

        <<~CTX
          #{label}:
          #{text}
        CTX
      end

      private

      def cache_key_for(query, filters)
        "#{query}:#{filters.to_json}"
      end

      def cosine_similarity(vec_a, vec_b)
        return 0.0 if vec_a.nil? || vec_b.nil? || vec_a.empty? || vec_b.empty?

        dot = vec_a.zip(vec_b).sum { |x, y| (x || 0.0) * (y || 0.0) }
        mag_a = Math.sqrt(vec_a.sum { |x| x * x })
        mag_b = Math.sqrt(vec_b.sum { |x| x * x })

        return 0.0 if mag_a.zero? || mag_b.zero?

        dot / (mag_a * mag_b)
      end

      def format_result(result)
        meta = result.document.metadata || {}
        source = meta['source'] || result.document.id
        <<~TXT
          [score: #{format('%.3f', result.score)} | source: #{source}]
          #{result.document.content}
        TXT
      end

      def apply_filters(results, filters)
        return results if filters.empty?

        results.select do |result|
          meta = result.document.metadata || {}
          filters.all? { |key, value| meta[key.to_s] == value }
        end
      end
    end
  end
end
