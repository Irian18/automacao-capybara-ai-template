# frozen_string_literal: true

module SelfHealing
  module Rag
    Document = Struct.new(:id, :content, :metadata, :embedding, keyword_init: true) do
      def to_h
        {
          'id' => id,
          'content' => content,
          'metadata' => metadata || {},
          'embedding' => embedding
        }
      end

      def self.from_hash(hash)
        new(
          id: hash['id'],
          content: hash['content'],
          metadata: hash['metadata'] || {},
          embedding: hash['embedding']
        )
      end
    end
  end
end
