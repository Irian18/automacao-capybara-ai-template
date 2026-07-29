# frozen_string_literal: true

require_relative '../spec_helper'

describe SelfHealing::Rag::Document do
  it 'converte para hash' do
    doc = SelfHealing::Rag::Document.new(
      id: 'doc:1',
      content: 'conteúdo',
      metadata: { 'source' => 'teste' },
      embedding: [0.1, 0.2]
    )

    hash = doc.to_h
    assert_equal 'doc:1', hash['id']
    assert_equal 'conteúdo', hash['content']
    assert_equal({ 'source' => 'teste' }, hash['metadata'])
    assert_equal [0.1, 0.2], hash['embedding']
  end

  it 'cria a partir de hash' do
    hash = {
      'id' => 'doc:2',
      'content' => 'outro conteúdo',
      'metadata' => { 'source' => 'outro' },
      'embedding' => [0.3, 0.4]
    }

    doc = SelfHealing::Rag::Document.from_hash(hash)
    assert_equal 'doc:2', doc.id
    assert_equal 'outro conteúdo', doc.content
    assert_equal({ 'source' => 'outro' }, doc.metadata)
    assert_equal [0.3, 0.4], doc.embedding
  end

  it 'usa metadata vazio ao serializar quando não informado' do
    doc = SelfHealing::Rag::Document.new(id: 'doc:3', content: 'x')
    assert_nil doc.metadata
    assert_equal({}, doc.to_h['metadata'])
  end
end
