require 'json'
require 'fileutils'
require 'securerandom'
require 'time'

module SelfHealing
  class LocatorHistory
    DEFAULT_PATH = File.expand_path('locator_history.json', __dir__)
    SCHEMA_VERSION = '1.1.0'

    def initialize(path: DEFAULT_PATH)
      @path = path
      ensure_file!
    end

    def record(page_object:, element_name:, version:, locator:, reason: nil, change_type: 'heal')
      data = load

      entry = find_entry(data, page_object, element_name)

      if entry
        entry['change_type'] = change_type.to_s
        entry['reason'] = reason.to_s
        entry['timestamp'] = Time.now.iso8601(6)
        add_locator(entry, version, locator)
      else
        entry = {
          'id' => SecureRandom.uuid,
          'timestamp' => Time.now.iso8601(6),
          'page_object' => page_object.to_s,
          'element_name' => element_name.to_s,
          'change_type' => change_type.to_s,
          'reason' => reason.to_s,
          'locators' => [
            { 'version' => version.to_i, 'locator' => locator.to_s }
          ]
        }
        data['entries'] << entry
      end

      data['metadata']['total_entries'] = data['entries'].size
      data['metadata']['updated_at'] = Time.now.iso8601(6)

      write(data)
      entry
    end

    def all
      load['entries'].sort_by { |e| e['timestamp'] }.reverse
    end

    def for_page_object(page_object)
      all.select { |e| e['page_object'] == page_object.to_s }
    end

    def for_element(element_name)
      all.select { |e| e['element_name'] == element_name.to_s }
    end

    def find(page_object:, element_name:)
      all.find { |e| e['page_object'] == page_object.to_s && e['element_name'] == element_name.to_s }
    end

    def for_change_type(change_type)
      all.select { |e| e['change_type'] == change_type.to_s }
    end

    def last
      all.first
    end

    private

    def find_entry(data, page_object, element_name)
      data['entries'].find do |e|
        e['page_object'] == page_object.to_s && e['element_name'] == element_name.to_s
      end
    end

    def add_locator(entry, version, locator)
      version_int = version.to_i
      exists = entry['locators'].any? { |l| l['version'] == version_int && l['locator'] == locator.to_s }
      return if exists

      entry['locators'] << { 'version' => version_int, 'locator' => locator.to_s }
      entry['locators'].sort_by! { |l| l['version'] }
    end

    def ensure_file!
      return if File.exist?(@path)

      FileUtils.mkdir_p(File.dirname(@path))
      write(initial_data)
    end

    def initial_data
      {
        'schema_version' => SCHEMA_VERSION,
        'metadata' => {
          'description' => 'Histórico de alterações de locators detectadas pelo Self Healing',
          'created_at' => Time.now.iso8601(6),
          'updated_at' => Time.now.iso8601(6),
          'total_entries' => 0
        },
        'entries' => []
      }
    end

    def load
      JSON.parse(File.read(@path))
    rescue JSON::ParserError => e
      warn "[SelfHealing::LocatorHistory] Arquivo corrompido em #{@path}: #{e.message}. Criando novo."
      initial_data
    end

    def write(data)
      temp_path = "#{@path}.tmp"
      File.write(temp_path, JSON.pretty_generate(data))
      File.rename(temp_path, @path)
    end
  end
end
