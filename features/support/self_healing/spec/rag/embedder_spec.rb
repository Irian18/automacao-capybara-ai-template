# frozen_string_literal: true

require_relative '../spec_helper'

class FakeOpenAIClient
  attr_reader :calls

  def initialize(responses = {})
    @responses = responses
    @calls = []
  end

  def embeddings(parameters:)
    @calls << parameters
    response = @responses[@calls.size - 1]
    raise response[:error] if response.is_a?(Hash) && response[:error]

    response
  end
end

describe SelfHealing::Rag::KeywordEmbedder do
  before do
    @embedder = SelfHealing::Rag::KeywordEmbedder.new
  end

  it 'gera um vetor de embedding' do
    vector = @embedder.embed('login usuário senha')
    assert_equal SelfHealing::Rag::KeywordEmbedder::DIMENSIONS, vector.size
    assert(vector.all? { |v| v.is_a?(Float) })
  end

  it 'gera vetores diferentes para textos diferentes' do
    v1 = @embedder.embed('fluxo de login com usuario e senha')
    v2 = @embedder.embed('listagem de produtos com preco e carrinho')
    refute_equal v1, v2
  end

  it 'normaliza o vetor para magnitude 1' do
    vector = @embedder.embed('palavra outra palavra')
    magnitude = Math.sqrt(vector.sum { |v| v * v })
    assert_in_delta 1.0, magnitude, 0.001
  end

  it 'retorna vetor zero para texto vazio' do
    vector = @embedder.embed('')
    assert vector.all?(&:zero?)
  end

  it 'ignora palavras muito curtas' do
    v1 = @embedder.embed('a b c')
    assert v1.all?(&:zero?)
  end

  it 'ignora task pois não é aplicável a embedder local' do
    vector = @embedder.embed('login', task: 'retrieval.query')
    assert_equal SelfHealing::Rag::KeywordEmbedder::DIMENSIONS, vector.size
  end
end

describe SelfHealing::Rag::Embedder do
  it 'KeywordEmbedder é o default quando modelo de embedding não está configurado' do
    ENV['RAG_EMBEDDING_MODEL'] = ''
    embedder = SelfHealing::Rag::Embedder.default
    assert_instance_of SelfHealing::Rag::KeywordEmbedder, embedder
  ensure
    ENV.delete('RAG_EMBEDDING_MODEL')
  end
end

describe SelfHealing::Rag::ApiEmbedder do
  before do
    @original_model = ENV.fetch('RAG_EMBEDDING_MODEL', nil)
    ENV['RAG_EMBEDDING_MODEL'] = 'jina-embeddings-v3'
  end

  after do
    ENV['RAG_EMBEDDING_MODEL'] = @original_model
  end

  it 'envia dimensions e task quando configurados' do
    embedder = SelfHealing::Rag::ApiEmbedder.new(
      api_key: 'test-key',
      base_url: 'https://api.jina.ai/v1',
      model: 'jina-embeddings-v3',
      dimensions: 256
    )

    fake_client = FakeOpenAIClient.new([
                                         { 'data' => [{ 'embedding' => [0.1, 0.2, 0.3] }] }
                                       ])
    embedder.instance_variable_set(:@client, fake_client)

    result = embedder.embed('login usuário', task: 'retrieval.passage')

    assert_equal [0.1, 0.2, 0.3], result
    call = fake_client.calls.first
    assert_equal 'jina-embeddings-v3', call[:model]
    assert_equal 'login usuário', call[:input]
    assert_equal 256, call[:dimensions]
    assert_equal 'retrieval.passage', call[:task]
  end

  it 'não envia dimensions quando não configurado' do
    embedder = SelfHealing::Rag::ApiEmbedder.new(
      api_key: 'test-key',
      base_url: 'https://api.jina.ai/v1',
      model: 'jina-embeddings-v3',
      dimensions: nil
    )

    fake_client = FakeOpenAIClient.new([
                                         { 'data' => [{ 'embedding' => [0.1, 0.2] }] }
                                       ])
    embedder.instance_variable_set(:@client, fake_client)

    embedder.embed('login', task: 'retrieval.query')

    call = fake_client.calls.first
    assert_equal 'jina-embeddings-v3', call[:model]
    refute call.key?(:dimensions)
    assert_equal 'retrieval.query', call[:task]
  end

  it 'faz fallback para KeywordEmbedder quando a API falha' do
    embedder = SelfHealing::Rag::ApiEmbedder.new(
      api_key: 'test-key',
      base_url: 'https://api.jina.ai/v1',
      model: 'jina-embeddings-v3',
      dimensions: nil
    )

    fake_client = FakeOpenAIClient.new([{ error: StandardError.new('API indisponível') }])
    embedder.instance_variable_set(:@client, fake_client)

    result = embedder.embed('login usuário')
    assert_equal SelfHealing::Rag::KeywordEmbedder::DIMENSIONS, result.size
  end
end
