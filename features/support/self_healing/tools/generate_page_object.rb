# frozen_string_literal: true

require_relative 'base'
require_relative '../page_object_generator'

module SelfHealing
  module Tools
    class GeneratePageObject < Base
      def definition
        {
          name: 'generate_page_object',
          description: 'Gera um arquivo SitePrism Page Object a partir do HTML ' \
                        'renderizado da página atual usando IA (LLM). Tem custo de API.',
          parameters: {
            type: 'object',
            properties: {
              page_name: { type: 'string', description: 'Nome CamelCase da classe, ex: "ClientRegisterPage"' },
              url: { type: 'string', description: 'URL da página. Padrão: current_path' },
              output_dir: { type: 'string', description: 'Diretório de saída. Padrão: tmp/page_objects/generated' }
            },
            required: ['page_name']
          }
        }
      end

      def execute(input)
        generator = PageObjectGenerator.new(session:)
        file_path = generator.generate(
          input['page_name'],
          url: input['url'],
          output_dir: input['output_dir']
        )
        "PAGE_OBJECT_GENERATED: #{file_path}"
      end

      def recordable?
        false
      end
    end
  end
end
