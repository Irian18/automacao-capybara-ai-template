# frozen_string_literal: true

require 'json'
require 'fileutils'
require_relative '../config'
require_relative 'document'

module SelfHealing
  module Rag
    class Store
      def initialize(store_path: Config.rag_store_path)
        @store_path = store_path
        FileUtils.mkdir_p(@store_path)
      end

      def add(document)
        documents = load_all
        documents[document.id] = document.to_h
        save(documents)
        document
      end

      def add_batch(docs)
        documents = load_all
        docs.each do |doc|
          documents[doc.id] = doc.to_h
        end
        save(documents)
        docs
      end

      def get(id)
        data = load_all[id]
        data ? Document.from_hash(data) : nil
      end

      def delete(id)
        documents = load_all
        documents.delete(id)
        save(documents)
      end

      def clear
        File.delete(index_path) if File.exist?(index_path)
      end

      def all
        load_all.values.map { |data| Document.from_hash(data) }
      end

      def size
        load_all.size
      end

      private

      def index_path
        File.join(@store_path, 'index.json')
      end

      def load_all
        return {} unless File.exist?(index_path)

        JSON.parse(File.read(index_path))
      rescue JSON::ParserError => e
        warn "[SelfHealing::Rag::Store] Índice corrompido: #{e.message}. Recriando."
        {}
      end

      def save(documents)
        File.write(index_path, JSON.pretty_generate(documents))
      end
    end
  end
end
