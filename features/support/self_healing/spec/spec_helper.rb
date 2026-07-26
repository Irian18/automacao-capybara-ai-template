# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/spec'
require 'fileutils'
require 'tmpdir'

$LOAD_PATH.unshift File.expand_path('..', __dir__)

require_relative '../plan_cache'
require_relative '../page_object_generator'
require_relative '../conversation'
require_relative '../tools'
require_relative '../rag/knowledge_base'
require_relative '../rag/store'

module SelfHealing
  # Helpers compartilhados entre os specs do SelfHealing.
  module Test
    def self.tmp_dir
      @tmp_dir ||= Dir.mktmpdir('self_healing_spec')
    end

    def self.clean_tmp_dir
      return unless @tmp_dir && Dir.exist?(@tmp_dir)

      FileUtils.rm_rf(@tmp_dir)
      @tmp_dir = nil
    end
  end
end

Minitest.after_run do
  SelfHealing::Test.clean_tmp_dir
end
