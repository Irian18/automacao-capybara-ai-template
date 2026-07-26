# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require_relative 'spec_helper'

describe SelfHealing::Conversation do
  before do
    @conversation = SelfHealing::Conversation.new
  end

  it 'inicia vazia' do
    assert @conversation.empty?
    assert_empty @conversation.messages
  end

  it 'adiciona mensagens system e user' do
    @conversation.system('Você é um agente')
    @conversation.user('Faça login')

    refute @conversation.empty?
    assert_equal 2, @conversation.messages.size
    assert_equal 'system', @conversation.messages[0]['role']
    assert_equal 'user', @conversation.messages[1]['role']
  end

  it 'adiciona mensagem assistant com tool_calls' do
    @conversation.assistant(
      { 'role' => 'assistant', 'content' => 'ok' },
      tool_calls: [{ 'id' => '1', 'function' => { 'name' => 'click' } }]
    )

    message = @conversation.messages.last
    assert_equal 'assistant', message['role']
    assert_equal 1, message['tool_calls'].size
  end

  it 'adiciona mensagem de tool' do
    @conversation.tool(tool_call_id: '1', name: 'click', content: 'OK')

    message = @conversation.messages.last
    assert_equal 'tool', message['role']
    assert_equal '1', message['tool_call_id']
    assert_equal 'click', message['name']
  end

  it 'limpa mensagens' do
    @conversation.user('teste')
    @conversation.clear

    assert @conversation.empty?
  end
end
# rubocop:enable Metrics/BlockLength
