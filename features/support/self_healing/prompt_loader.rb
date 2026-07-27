require 'erb'
require 'digest'

module SelfHealing
  class PromptLoader
    PROMPTS_DIR = File.expand_path('prompts', __dir__)

    def self.render(name, **locals)
      path = File.join(PROMPTS_DIR, "#{name}.md.erb")
      raise ArgumentError, "Prompt template não encontrado: #{path}" unless File.exist?(path)

      template = File.read(path, encoding: 'UTF-8')
      ERB.new(template, trim_mode: '-').result_with_hash(locals)
    end

    def self.prompt_hash
      @prompt_hash ||= begin
        files = Dir.glob(File.join(PROMPTS_DIR, '*.md.erb')).sort
        content = files.map { |f| File.read(f, encoding: 'UTF-8') }.join
        Digest::SHA256.hexdigest(content)[0, 16]
      end
    end

    def self.read_page_object_prompt
      path = File.join(PROMPTS_DIR, 'page_object_design_system.md')
      return '' unless File.exist?(path)

      File.read(path, encoding: 'UTF-8')
    end
  end
end
