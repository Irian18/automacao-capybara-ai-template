# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require_relative 'spec_helper'

describe SelfHealing::Rag::KnowledgeBase do
  before do
    @test_id = Random.rand(10_000)
    @base_dir = File.join(SelfHealing::Test.tmp_dir, "knowledge_base_#{@test_id}")
    @store_dir = File.join(SelfHealing::Test.tmp_dir, "rag_store_#{@test_id}")
    FileUtils.mkdir_p(@base_dir)
    FileUtils.mkdir_p(@store_dir)

    @store = SelfHealing::Rag::Store.new(store_path: @store_dir)
    @kb = SelfHealing::Rag::KnowledgeBase.new(
      base_dir: @base_dir,
      store: @store,
      embedder: SelfHealing::Rag::KeywordEmbedder.new
    )
  end

  it 'indexa arquivos da knowledge base' do
    File.write(File.join(@base_dir, 'login.md'), '# Fluxo de Login')

    count = @kb.index!
    assert_equal 1, count
    assert_equal 2, @store.size # documento + meta
  end

  it 'considera fresh quando nenhum arquivo mudou' do
    File.write(File.join(@base_dir, 'login.md'), '# Fluxo de Login')
    @kb.index!

    assert @kb.fresh?

    count = @kb.index!
    assert_equal :fresh, count
  end

  it 'não considera fresh quando arquivo é modificado' do
    path = File.join(@base_dir, 'login.md')
    File.write(path, '# Fluxo de Login')
    @kb.index!

    sleep 1.1
    File.write(path, '# Fluxo de Login Atualizado')

    refute @kb.fresh?
  end

  it 'remove documentos stale' do
    stale_path = File.join(@base_dir, 'stale.md')
    File.write(stale_path, '# Stale')
    @kb.index!

    File.delete(stale_path)
    @kb.index!

    assert_nil @store.get('kb:stale.md')
  end
end
# rubocop:enable Metrics/BlockLength
