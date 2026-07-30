# frozen_string_literal: true

require_relative 'spec_helper'

describe SelfHealing::Config do
  before do
    @original_env = ENV.to_h
  end

  after do
    ENV.clear
    ENV.update(@original_env)
  end

  it 'rag_embedding_dimensions retorna nil quando não configurado' do
    ENV.delete('RAG_EMBEDDING_DIMENSIONS')
    assert_nil SelfHealing::Config.rag_embedding_dimensions
  end

  it 'rag_embedding_dimensions retorna inteiro quando configurado' do
    ENV['RAG_EMBEDDING_DIMENSIONS'] = '512'
    assert_equal 512, SelfHealing::Config.rag_embedding_dimensions
  end

  it 'rag_embedding_task retorna string vazia por padrão' do
    ENV.delete('RAG_EMBEDDING_TASK')
    assert_equal '', SelfHealing::Config.rag_embedding_task
  end

  it 'rag_embedding_task_passage retorna nil quando task não está configurada' do
    ENV.delete('RAG_EMBEDDING_TASK')
    assert_nil SelfHealing::Config.rag_embedding_task_passage
  end

  it 'rag_embedding_task_passage retorna task configurada' do
    ENV['RAG_EMBEDDING_TASK'] = 'retrieval.passage'
    assert_equal 'retrieval.passage', SelfHealing::Config.rag_embedding_task_passage
  end

  it 'rag_embedding_task_query retorna task específica de query' do
    ENV['RAG_EMBEDDING_TASK_QUERY'] = 'retrieval.query'
    assert_equal 'retrieval.query', SelfHealing::Config.rag_embedding_task_query
  end

  it 'rag_embedding_config_key combina modelo, dimensões e task' do
    ENV['RAG_EMBEDDING_MODEL'] = 'jina-embeddings-v3'
    ENV['RAG_EMBEDDING_DIMENSIONS'] = '256'
    ENV['RAG_EMBEDDING_TASK'] = 'retrieval.passage'

    assert_equal 'jina-embeddings-v3|256|retrieval.passage', SelfHealing::Config.rag_embedding_config_key
  end

  it 'rag_embedding_config_key ignora task vazia' do
    ENV['RAG_EMBEDDING_MODEL'] = 'text-embedding-3-small'
    ENV.delete('RAG_EMBEDDING_TASK')
    ENV.delete('RAG_EMBEDDING_DIMENSIONS')

    assert_equal 'text-embedding-3-small|', SelfHealing::Config.rag_embedding_config_key
  end

  it 'rag_knowledge_base_dirs retorna um único diretório como array' do
    ENV['RAG_KNOWLEDGE_BASE_DIR'] = 'features/pages'
    assert_equal ['features/pages'], SelfHealing::Config.rag_knowledge_base_dirs
  end

  it 'rag_knowledge_base_dirs retorna múltiplos diretórios separados por vírgula' do
    ENV['RAG_KNOWLEDGE_BASE_DIR'] = 'features/pages,features/support/self_healing/knowledge_base'
    assert_equal ['features/pages', 'features/support/self_healing/knowledge_base'],
                 SelfHealing::Config.rag_knowledge_base_dirs
  end

  it 'rag_knowledge_base_dirs ignora espaços e entradas vazias' do
    ENV['RAG_KNOWLEDGE_BASE_DIR'] = 'features/pages ; ; features/support/self_healing/knowledge_base'
    assert_equal ['features/pages', 'features/support/self_healing/knowledge_base'],
                 SelfHealing::Config.rag_knowledge_base_dirs
  end

  it 'rag_knowledge_base_dir retorna o primeiro diretório para compatibilidade' do
    ENV['RAG_KNOWLEDGE_BASE_DIR'] = 'features/pages,features/support/self_healing/knowledge_base'
    assert_equal 'features/pages', SelfHealing::Config.rag_knowledge_base_dir
  end
end
