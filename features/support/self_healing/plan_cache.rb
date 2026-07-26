# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'digest'
require 'time'

module SelfHealing
  # Persistência de planos cacheados gerados pelo agente.
  # Suporta invalidação por hash de prompt e TTL opcional.
  class PlanCache
    PLANS_DIR = File.expand_path('plans', __dir__)
    DEFAULT_TTL_SECONDS = nil # nil = sem expiração

    def initialize(plans_dir: PLANS_DIR, ttl_seconds: DEFAULT_TTL_SECONDS)
      @dir = plans_dir
      @ttl_seconds = ttl_seconds
      FileUtils.mkdir_p(@dir)
    end

    def load(instruction)
      path = path_for(instruction)
      return nil unless File.exist?(path)

      data = JSON.parse(File.read(path))
      return nil if expired?(data)

      cached_prompt_hash = data['prompt_hash']
      current_prompt_hash = PromptLoader.prompt_hash
      if cached_prompt_hash && cached_prompt_hash != current_prompt_hash
        warn "[SelfHealing] Cache invalidado: prompt mudou (#{cached_prompt_hash} != #{current_prompt_hash})"
        return nil
      end

      Plan.new(
        instruction: data['instruction'],
        steps: data['steps'],
        version: data['version'] || 1,
        updated_at: data['updated_at'],
        heal_reason: data['heal_reason']
      )
    rescue JSON::ParserError => e
      warn "[SelfHealing] Cache corrompido em #{path}: #{e.message}. Ignorando."
      nil
    end

    def save(plan)
      path = path_for(plan.instruction)
      data = {
        'instruction' => plan.instruction,
        'version' => plan.version,
        'updated_at' => Time.now.iso8601,
        'prompt_hash' => PromptLoader.prompt_hash,
        'steps' => plan.steps
      }
      data['heal_reason'] = plan.heal_reason if plan.heal_reason

      write_atomic(path, JSON.pretty_generate(data))
      path
    end

    def delete(instruction)
      path = path_for(instruction)
      FileUtils.rm_f(path)
    end

    def exists?(instruction)
      File.exist?(path_for(instruction))
    end

    private

    def expired?(data)
      return false unless @ttl_seconds
      return false unless data['updated_at']

      updated_at = Time.iso8601(data['updated_at'])
      expired = (Time.now - updated_at) > @ttl_seconds
      warn "[SelfHealing] Cache expirado (#{@ttl_seconds}s). Ignorando." if expired
      expired
    rescue ArgumentError
      false
    end

    def write_atomic(path, content)
      temp_path = "#{path}.tmp"
      File.write(temp_path, content)
      File.rename(temp_path, path)
    end

    def path_for(instruction)
      File.join(@dir, "#{slug(instruction)}.json")
    end

    def slug(instruction)
      base = instruction.downcase
                        .gsub(/[^\w\s-]/, '')
                        .strip
                        .gsub(/\s+/, '_')[0, 60]
      hash = Digest::SHA1.hexdigest(instruction)[0, 8]
      "#{base}__#{hash}"
    end
  end

  Plan = Struct.new(:instruction, :steps, :version, :updated_at, :heal_reason, keyword_init: true) do
    def to_h
      members.each_with_object({}) { |k, h| h[k.to_s] = self[k] }
    end
  end
end
