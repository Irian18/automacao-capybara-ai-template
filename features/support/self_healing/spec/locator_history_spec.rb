# frozen_string_literal: true

require_relative 'spec_helper'
require_relative '../locator_history'

require 'json'
require 'fileutils'

describe SelfHealing::LocatorHistory do
  let(:tmp_path) { File.join(SelfHealing::Test.tmp_dir, 'locator_history_test.json') }
  let(:history) { SelfHealing::LocatorHistory.new(path: tmp_path) }

  before do
    FileUtils.rm_f(tmp_path)
  end

  it 'cria o arquivo inicial se não existir' do
    history
    assert File.exist?(tmp_path)
    data = JSON.parse(File.read(tmp_path))
    assert_equal '1.1.0', data['schema_version']
    assert_equal 0, data['metadata']['total_entries']
    assert_equal [], data['entries']
  end

  it 'registra uma nova entrada com array de locators' do
    entry = history.record(
      page_object: 'LoginPage',
      element_name: 'in_user_id',
      version: 1,
      locator: '#email',
      reason: 'registro inicial',
      change_type: 'record'
    )

    assert_equal 'LoginPage', entry['page_object']
    assert_equal 'in_user_id', entry['element_name']
    assert_equal 'record', entry['change_type']
    refute_nil entry['id']
    refute_nil entry['timestamp']
    assert_equal [{ 'version' => 1, 'locator' => '#email' }], entry['locators']

    data = JSON.parse(File.read(tmp_path))
    assert_equal 1, data['metadata']['total_entries']
    assert_equal 1, data['entries'].size
  end

  it 'acumula versões de locator no mesmo elemento' do
    history.record(page_object: 'LoginPage', element_name: 'in_user_id',
                   version: 1, locator: '#email', change_type: 'record')
    history.record(page_object: 'LoginPage', element_name: 'in_user_id',
                   version: 2, locator: '#user-name', change_type: 'heal',
                   reason: 'ID mudou')

    entry = history.find(page_object: 'LoginPage', element_name: 'in_user_id')
    assert_equal 2, entry['locators'].size
    assert_equal({ 'version' => 1, 'locator' => '#email' }, entry['locators'][0])
    assert_equal({ 'version' => 2, 'locator' => '#user-name' }, entry['locators'][1])
  end

  it 'não duplica locator com mesma versão e mesmo valor' do
    history.record(page_object: 'LoginPage', element_name: 'in_user_id',
                   version: 1, locator: '#email')
    history.record(page_object: 'LoginPage', element_name: 'in_user_id',
                   version: 1, locator: '#email')

    entry = history.find(page_object: 'LoginPage', element_name: 'in_user_id')
    assert_equal 1, entry['locators'].size
  end

  it 'retorna entradas ordenadas da mais recente para a mais antiga' do
    history.record(page_object: 'LoginPage', element_name: 'a',
                   version: 1, locator: '#a1')
    sleep 0.01
    history.record(page_object: 'LoginPage', element_name: 'b',
                   version: 1, locator: '#b1')

    all = history.all
    assert_equal 2, all.size
    assert_equal 'b', all.first['element_name']
    assert_equal 'a', all.last['element_name']
  end

  it 'filtra por page_object' do
    history.record(page_object: 'LoginPage', element_name: 'a',
                   version: 1, locator: '#a1')
    history.record(page_object: 'ProductsPage', element_name: 'b',
                   version: 1, locator: '#b1')

    assert_equal 1, history.for_page_object('LoginPage').size
    assert_equal 'a', history.for_page_object('LoginPage').first['element_name']
  end

  it 'filtra por element_name' do
    history.record(page_object: 'LoginPage', element_name: 'in_user_id',
                   version: 1, locator: '#a1')
    history.record(page_object: 'LoginPage', element_name: 'in_password',
                   version: 1, locator: '#b1')

    assert_equal 1, history.for_element('in_user_id').size
  end

  it 'retorna a última entrada' do
    history.record(page_object: 'LoginPage', element_name: 'a',
                   version: 1, locator: '#a1')
    sleep 0.01
    history.record(page_object: 'LoginPage', element_name: 'b',
                   version: 1, locator: '#b1')

    assert_equal 'b', history.last['element_name']
  end
end
