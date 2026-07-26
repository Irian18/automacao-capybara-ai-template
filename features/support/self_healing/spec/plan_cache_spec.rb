# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require_relative 'spec_helper'

describe SelfHealing::PlanCache do
  before do
    @dir = File.join(SelfHealing::Test.tmp_dir, 'plans')
    @cache = SelfHealing::PlanCache.new(plans_dir: @dir)
  end

  it 'salva e carrega um plano' do
    plan = SelfHealing::Plan.new(
      instruction: 'clicar no botão salvar',
      steps: [{ 'name' => 'click', 'input' => { 'text' => 'Salvar' } }],
      version: 1
    )

    @cache.save(plan)
    loaded = @cache.load('clicar no botão salvar')

    refute_nil loaded
    assert_equal 'clicar no botão salvar', loaded.instruction
    assert_equal 1, loaded.steps.size
    assert_equal 1, loaded.version
  end

  it 'detecta existência de cache' do
    refute @cache.exists?('instrução inexistente')

    plan = SelfHealing::Plan.new(instruction: 'instrução existente', steps: [], version: 1)
    @cache.save(plan)

    assert @cache.exists?('instrução existente')
  end

  it 'remove cache ao deletar' do
    plan = SelfHealing::Plan.new(instruction: 'remover', steps: [], version: 1)
    @cache.save(plan)
    assert @cache.exists?('remover')

    @cache.delete('remover')
    refute @cache.exists?('remover')
  end

  it 'gera slugs distintos para instruções diferentes' do
    a = @cache.send(:slug, 'clicar em salvar')
    b = @cache.send(:slug, 'clicar em cancelar')

    refute_equal a, b
    assert_match(/__\h{8}\z/, a)
  end
end
# rubocop:enable Metrics/BlockLength
