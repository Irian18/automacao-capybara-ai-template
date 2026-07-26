# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require_relative 'spec_helper'

describe SelfHealing::Tools do
  before do
    @session = Object.new
    @context = SelfHealing::Tools::Context.new(session: @session, page_object: nil, helper: nil)
    @registry = SelfHealing::Tools::Registry.new(@context)
  end

  it 'carrega todas as tools' do
    definitions = @registry.definitions
    names = definitions.map { |d| d[:function][:name] }

    assert_includes names, 'inspect_page'
    assert_includes names, 'click'
    assert_includes names, 'fill_in'
    assert_includes names, 'visit'
    assert_includes names, 'finish'
    assert_includes names, 'fail_test'
  end

  it 'finish não é gravável' do
    refute @registry.recordable?('finish')
  end

  it 'click é gravável' do
    assert @registry.recordable?('click')
  end

  it 'dispatch finish retorna summary' do
    result = @registry.dispatch(name: 'finish', input: { 'summary' => 'ok' })
    assert_equal 'FINISHED: ok', result
  end

  it 'dispatch fail_test lança exceção' do
    assert_raises(SelfHealing::TestFailed) do
      @registry.dispatch(name: 'fail_test', input: { 'reason' => 'erro' })
    end
  end

  it 'dispatch tool desconhecida lança erro' do
    assert_raises(ArgumentError) do
      @registry.dispatch(name: 'inexistente', input: {})
    end
  end
end
# rubocop:enable Metrics/BlockLength
