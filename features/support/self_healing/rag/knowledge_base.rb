# frozen_string_literal: true

require 'digest'
require 'pathname'
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
        base_dirs: Config.rag_knowledge_base_dirs,
        store: Store.new,
        embedder: Embedder.default
      )
        @base_dirs = Array(base_dirs)
        @store = store
        @embedder = embedder
      end

      def embedding_config_key
        Config.rag_embedding_config_key
      end

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

      def fresh?
        meta = @store.get(INDEX_META_ID)
        return false unless meta

        stored_mtimes = meta.metadata['mtimes'] || {}
        stored_config = meta.metadata['embedding_config']
        current_files = collect_files
        current_mtimes = current_files.to_h { |path| [file_key(path), File.mtime(path).to_i] }

        stored_config == embedding_config_key &&
          stored_mtimes == current_mtimes &&
          current_files.none? { |path| File.mtime(path).to_i > stored_mtimes[file_key(path)].to_i }
      rescue StandardError => e
        warn "[SelfHealing::Rag::KnowledgeBase] Falha ao verificar freshness: #{e.class}: #{e.message}. Reindexando."
        false
      end

      def add_text(content, id:, source: nil, metadata: {})
        doc = Document.new(
          id:,
          content:,
          metadata: metadata.merge('source' => source || id),
          embedding: @embedder.embed(content, task: Config.rag_embedding_task_passage)
        )
        @store.add(doc)
      end

      private

      def collect_files
        @base_dirs.flat_map do |base_dir|
          next [] unless Dir.exist?(base_dir)

          Dir.glob(File.join(base_dir, '**', '*')).select do |path|
            File.file?(path) && SUPPORTED_EXTENSIONS.include?(File.extname(path).downcase)
          end
        end
      end

      def file_to_document(path)
        content = File.read(path, encoding: 'UTF-8')
        key = file_key(path)
        id = "kb:#{key}"

        Document.new(
          id:,
          content:,
          metadata: {
            'source' => key,
            'type' => type_from_path(path)
          },
          embedding: nil
        )
      end

      def file_key(path)
        base_dir = @base_dirs.find { |dir| path.start_with?(dir) }
        return path unless base_dir

        Pathname.new(path).relative_path_from(Pathname.new(base_dir)).to_s
      end

      def embed_missing!(documents)
        documents.each do |doc|
          doc.embedding = @embedder.embed(doc.content, task: Config.rag_embedding_task_passage) if doc.embedding.nil?
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
        mtimes = files.to_h { |path| [file_key(path), File.mtime(path).to_i] }

        meta = Document.new(
          id: INDEX_META_ID,
          content: 'Index metadata',
          metadata: {
            'source' => INDEX_META_ID,
            'type' => 'meta',
            'mtimes' => mtimes,
            'indexed_at' => Time.now.iso8601,
            'embedding_config' => embedding_config_key
          },
          embedding: nil
        )
        @store.add(meta)
      end
    end
  end
end
