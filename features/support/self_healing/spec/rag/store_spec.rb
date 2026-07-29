# frozen_string_literal: true

require_relative '../spec_helper'

describe SelfHealing::Rag::Store do
  before do
    @test_id = SecureRandom.uuid
    @store_dir = File.join(SelfHealing::Test.tmp_dir, "rag_store_#{@test_id}")
    FileUtils.rm_rf(@store_dir)
    @store = SelfHealing::Rag::Store.new(store_path: @store_dir)
  end

  after do
    FileUtils.rm_rf(@store_dir)
  end

  it 'adiciona um documento' do
    doc = SelfHealing::Rag::Document.new(
      id: 'doc:1',
      content: 'conteúdo',
      embedding: [0.1, 0.2]
    )

    @store.add(doc)
    assert_equal 1, @store.size

    retrieved = @store.get('doc:1')
    assert_equal 'conteúdo', retrieved.content
  end

  it 'atualiza documento existente' do
    doc = SelfHealing::Rag::Document.new(id: 'doc:1', content: 'original')
    @store.add(doc)

    updated = SelfHealing::Rag::Document.new(id: 'doc:1', content: 'atualizado')
    @store.add(updated)

    assert_equal 1, @store.size
    assert_equal 'atualizado', @store.get('doc:1').content
  end

  it 'adiciona batch de documentos' do
    docs = [
      SelfHealing::Rag::Document.new(id: 'doc:1', content: 'a'),
      SelfHealing::Rag::Document.new(id: 'doc:2', content: 'b')
    ]

    @store.add_batch(docs)
    assert_equal 2, @store.size
  end

  it 'remove documento' do
    doc = SelfHealing::Rag::Document.new(id: 'doc:1', content: 'x')
    @store.add(doc)
    @store.delete('doc:1')

    assert_nil @store.get('doc:1')
    assert_equal 0, @store.size
  end

  it 'lista todos os documentos' do
    @store.add(SelfHealing::Rag::Document.new(id: 'doc:1', content: 'a'))
    @store.add(SelfHealing::Rag::Document.new(id: 'doc:2', content: 'b'))

    all = @store.all
    assert_equal 2, all.size
    assert all.map(&:id).sort == ['doc:1', 'doc:2']
  end

  it 'limpa o índice' do
    @store.add(SelfHealing::Rag::Document.new(id: 'doc:1', content: 'x'))
    @store.clear

    assert_equal 0, @store.size
    assert_empty @store.all
  end

  it 'ignora índice corrompido' do
    index_path = File.join(@store_dir, 'index.json')
    File.write(index_path, 'invalid json')

    assert_equal 0, @store.size
    assert_empty @store.all
  end
end
