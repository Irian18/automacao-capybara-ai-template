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

    def apply_by_selector(old_selector:, new_selector:)
      files = find_files_with_selector(old_selector)

      if files.empty?
        return { status: :skipped, reason: 'nenhum arquivo de page object contém o selector' }
      end

      if files.size > 1
        return { status: :skipped, reason: 'múltiplos arquivos contêm o selector', files: files }
      end

      file_path = files.first
      content = File.read(file_path)
      updated, new_content = replace_selector(content, old_selector, new_selector)

      if updated
        File.write(file_path, new_content)
        { status: :applied, file: file_path, old_selector: old_selector, new_selector: new_selector }
      else
        { status: :not_found, reason: 'selector não encontrado no arquivo', file: file_path }
      end
    end

    private

    def find_page_object_file(page_object)
      Dir.glob(File.join(@pages_dir, '**', '*.rb')).find do |file|
        File.read(file).match?(/\bclass\s+#{Regexp.escape(page_object)}\s*</)
      end
    end

    def find_files_with_selector(selector)
      escaped = Regexp.escape(selector)
      Dir.glob(File.join(@pages_dir, '**', '*.rb')).select do |file|
        File.read(file).match?(/['"]#{escaped}['"]/)
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

    def replace_selector(content, old_selector, new_selector)
      pattern = /(['"])#{Regexp.escape(old_selector)}\1/

      updated = false
      new_content = content.gsub(pattern) do |match|
        updated = true
        quote = Regexp.last_match(1)
        "#{quote}#{new_selector}#{quote}"
      end

      [updated, new_content]
    end
  end
end
