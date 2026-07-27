# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require_relative 'spec_helper'

describe SelfHealing::PageObjectGenerator do
  before do
    @generator = SelfHealing::PageObjectGenerator.new(
      session: Object.new,
      output_dir: File.join(SelfHealing::Test.tmp_dir, 'page_objects')
    )
  end

  it 'extrai código Ruby de bloco markdown' do
    raw = <<~RAW
      Aqui está o código:

      ```ruby
      class LoginPage < SitePrism::Page
        set_url '/login'
      end
      ```

      Espero que ajude.
    RAW

    code = @generator.send(:extract_ruby_code, raw)

    assert_match(/class LoginPage/, code)
    refute_match(/Espero que ajude/, code)
  end

  it 'reconhece código Ruby sem markdown' do
    raw = <<~RAW
      class HomePage < SitePrism::Page
        set_url '/home'
      end
    RAW

    code = @generator.send(:extract_ruby_code, raw)
    assert_match(/class HomePage/, code)
  end

  it 'ignora conteúdo que não parece Ruby' do
    raw = 'Aqui só tem explicação em português sem código.'

    code = @generator.send(:extract_ruby_code, raw)
    refute_match(/class/, code)
    assert_match(/não parece Ruby válido/, code)
  end
end
# rubocop:enable Metrics/BlockLength
