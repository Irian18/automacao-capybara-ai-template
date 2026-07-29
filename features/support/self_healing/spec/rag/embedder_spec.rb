# frozen_string_literal: true

require_relative '../spec_helper'

describe SelfHealing::Rag::KeywordEmbedder do
  before do
    @embedder = SelfHealing::Rag::KeywordEmbedder.new
  end

  it 'gera um vetor de embedding' do
    vector = @embedder.embed('login usuário senha')
    assert_equal SelfHealing::Rag::KeywordEmbedder::DIMENSIONS, vector.size
    assert vector.all? { |v| v.is_a?(Float) }
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
