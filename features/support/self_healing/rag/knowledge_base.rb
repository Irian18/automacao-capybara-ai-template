# frozen_string_literal: true

require 'digest'
require 'pathname'
require 'set'
require 'yaml'
require 'time' # necessário para Time#iso8601
require_relative '../config'
require_relative 'document'
require_relative 'store'
require_relative 'embedder'

module SelfHealing
  module Rag
    class KnowledgeBase
      SUPPORTED_EXTENSIONS = %w[.md .txt .yml .yaml .rb .feature].freeze
      INDEX_META_ID = '__index_meta__'

      def initialize(
        base_dir: Config.rag_knowledge_base_dir,
        store: Store.new,
        embedder: Embedder.default
      )
        @base_dir = base_dir
        @store = store
        @embedder = embedder
      end

      # Indexa todos os arquivos suportados dentro da knowledge base.
      # Remove do índice arquivos que não existem mais.
      # Se a base não mudou desde a última indexação, não faz nada.
      def index!
        return :fresh if fresh?

        files = collect_files
        existing_ids = Set.new

        documents = files.map do |path|
          doc = file_to_document(path)
          existing_ids << doc.id
          doc
        end

        embed_missing!(documents)
        @store.add_batch(documents)

        remove_stale(existing_ids)
        save_index_meta!

        documents.size
      end

      # Verifica se a base de conhecimento foi indexada recentemente e
      # nenhum arquivo mudou desde então.
      def fresh?
        meta = @store.get(INDEX_META_ID)
        return false unless meta

        stored_mtimes = meta.metadata['mtimes'] || {}
        current_files = collect_files
        current_mtimes = current_files.to_h { |path| [relative_path(path), File.mtime(path).to_i] }

        stored_mtimes == current_mtimes &&
          current_files.none? { |path| File.mtime(path).to_i > stored_mtimes[relative_path(path)].to_i }
      rescue StandardError => e
        warn "[SelfHealing::Rag::KnowledgeBase] Falha ao verificar freshness: #{e.class}: #{e.message}. Reindexando."
        false
      end

      # Indexa um único arquivo ou texto.
      def add_text(content, id:, source: nil, metadata: {})
        doc = Document.new(
          id:,
          content:,
          metadata: metadata.merge('source' => source || id),
          embedding: @embedder.embed(content)
        )
        @store.add(doc)
      end

      private

      def collect_files
        return [] unless Dir.exist?(@base_dir)

        Dir.glob(File.join(@base_dir, '**', '*')).select do |path|
          File.file?(path) && SUPPORTED_EXTENSIONS.include?(File.extname(path).downcase)
        end
      end

      def file_to_document(path)
        content = File.read(path, encoding: 'UTF-8')
        relative = relative_path(path)
        id = "kb:#{relative}"

        Document.new(
          id:,
          content:,
          metadata: {
            'source' => relative,
            'type' => type_from_path(path)
          },
          embedding: nil
        )
      end

      def relative_path(path)
        Pathname.new(path).relative_path_from(Pathname.new(@base_dir)).to_s
      end

      def embed_missing!(documents)
        documents.each do |doc|
          doc.embedding = @embedder.embed(doc.content) if doc.embedding.nil?
        end
      end

      def remove_stale(existing_ids)
        @store.all.each do |doc|
          next unless doc.id.start_with?('kb:')

          @store.delete(doc.id) unless existing_ids.include?(doc.id)
        end
      end

      def type_from_path(path)
        ext = File.extname(path).downcase
        case ext
        when '.md', '.txt' then 'doc'
        when '.yml', '.yaml' then 'config'
        when '.rb' then 'page_object'
        when '.feature' then 'feature'
        else 'unknown'
        end
      end

      def save_index_meta!
        files = collect_files
        mtimes = files.to_h { |path| [relative_path(path), File.mtime(path).to_i] }

        meta = Document.new(
          id: INDEX_META_ID,
          content: 'Index metadata',
          metadata: {
            'source' => INDEX_META_ID,
            'type' => 'meta',
            'mtimes' => mtimes,
            'indexed_at' => Time.now.iso8601
          },
          embedding: nil
        )
        @store.add(meta)
      end
    end
  end
end
