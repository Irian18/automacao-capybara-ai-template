# frozen_string_literal: true

require_relative '../spec_helper'

describe SelfHealing::Rag::Retriever do
  before do
    @test_id = SecureRandom.uuid
    @store_dir = File.join(SelfHealing::Test.tmp_dir, "rag_store_#{@test_id}")
    FileUtils.rm_rf(@store_dir)
    @store = SelfHealing::Rag::Store.new(store_path: @store_dir)
    @embedder = SelfHealing::Rag::KeywordEmbedder.new

    @store.add_batch([
      SelfHealing::Rag::Document.new(
        id: 'doc:login',
        content: 'fluxo de login usuário senha',
        metadata: { 'type' => 'page_object' },
        embedding: @embedder.embed('fluxo de login usuário senha')
      ),
      SelfHealing::Rag::Document.new(
        id: 'doc:products',
        content: 'listagem de produtos preço carrinho',
        metadata: { 'type' => 'page_object' },
        embedding: @embedder.embed('listagem de produtos preço carrinho')
      ),
      SelfHealing::Rag::Document.new(
        id: 'doc:config',
        content: 'configuração do ambiente',
        metadata: { 'type' => 'config' },
        embedding: @embedder.embed('configuração do ambiente')
      )
    ])

    @retriever = SelfHealing::Rag::Retriever.new(
      store: @store,
      embedder: @embedder,
      top_k: 2,
      min_similarity: 0.0
    )
  end

  it 'retorna documentos ordenados por relevância' do
    results = @retriever.search('login usuário')
    assert_equal 2, results.size
    assert_equal 'doc:login', results.first.document.id
    assert results.first.score >= results.last.score
  end

  it 'respeita o limite top_k' do
    results = @retriever.search('login')
    assert_equal 2, results.size
  end

  it 'filtra por metadata' do
    results = @retriever.search('configuração', filters: { 'type' => 'config' })
    assert_equal 1, results.size
    assert_equal 'doc:config', results.first.document.id
  end

  it 'respeita min_similarity' do
    retriever = SelfHealing::Rag::Retriever.new(
      store: @store,
      embedder: @embedder,
      top_k: 10,
      min_similarity: 0.99
    )

    results = retriever.search('login')
    assert_empty results
  end

  it 'retorna vazio para store vazia' do
    empty_store = SelfHealing::Rag::Store.new(store_path: File.join(SelfHealing::Test.tmp_dir, "empty_#{@test_id}"))
    retriever = SelfHealing::Rag::Retriever.new(store: empty_store, embedder: @embedder)

    assert_empty retriever.search('login')
  end

  it 'formata contexto para prompts' do
    context = @retriever.context_for('login', label: 'CONTEXTO')
    refute_empty context
    assert_match(/CONTEXTO:/, context)
    assert_match(/doc:login/, context)
  end

  it 'retorna string vazia quando não há resultados' do
    retriever = SelfHealing::Rag::Retriever.new(
      store: @store,
      embedder: @embedder,
      min_similarity: 0.99
    )

    assert_empty retriever.context_for('nada a ver')
  end

  it 'cacheia resultados da mesma query' do
    result1 = @retriever.search('login')
    result2 = @retriever.search('login')
    assert_same result1, result2
  end

  it 'limpa cache' do
    @retriever.search('login')
    @retriever.clear_cache

    # Após limpar, uma nova busca deve retornar um objeto diferente
    result = @retriever.search('login')
    assert_equal 2, result.size
  end
end
