require 'json'
require_relative 'locator_history'

module SelfHealing
  class LocatorApplier
    PAGES_DIR = File.expand_path('../../pages', __dir__)

    def initialize(pages_dir: PAGES_DIR, history: nil)
      @pages_dir = pages_dir
      @history = history || LocatorHistory.new
    end

    def apply_all
      results = []

      @history.all.each do |entry|
        next unless entry['change_type'] == 'heal'
        next if entry['locators'].nil? || entry['locators'].empty?

        latest = entry['locators'].last
        result = apply(
          page_object: entry['page_object'],
          element_name: entry['element_name'],
          new_locator: latest['locator']
        )
        results << result
      end

      results
    end

    def apply(page_object:, element_name:, new_locator:)
      file_path = find_page_object_file(page_object)

      if file_path.nil?
        return {
          page_object: page_object,
          element_name: element_name,
          status: :skipped,
          reason: 'arquivo do page object não encontrado'
        }
      end

      content = File.read(file_path)
      updated, new_content = replace_locator(content, element_name, new_locator)

      if updated
        File.write(file_path, new_content)
        {
          page_object: page_object,
          element_name: element_name,
          file: file_path,
          new_locator: new_locator,
          status: :applied
        }
      else
        {
          page_object: page_object,
          element_name: element_name,
          file: file_path,
          new_locator: new_locator,
          status: :not_found,
          reason: 'declaração do elemento não encontrada no arquivo'
        }
      end
    end

    private

    def find_page_object_file(page_object)
      Dir.glob(File.join(@pages_dir, '**', '*.rb')).find do |file|
        File.read(file).match?(/\bclass\s+#{Regexp.escape(page_object)}\s*</)
      end
    end

    def replace_locator(content, element_name, new_locator)
      pattern = /(element|section|sections|iframe)\s+:#{Regexp.escape(element_name)}\s*,\s*(['"])[^'"]*\2/

      updated = false
      new_content = content.gsub(pattern) do |match|
        updated = true
        prefix = Regexp.last_match(1)
        quote = Regexp.last_match(2)
        "#{prefix} :#{element_name}, #{quote}#{new_locator}#{quote}"
      end

      [updated, new_content]
    end
  end
end
