require 'rake'
require 'cucumber'
require 'cucumber/rake/task'

namespace :cucumber do
  desc 'Executar todas as features no ambiente de CI'
  task :exec_ci do
    sh 'rm -rf report/html_report && mkdir -p report/html_report && touch report/html_report/report.html && bundle exec cucumber ENVIRONMENT_TYPE=ci BROWSER=cuprite --retry 2 --format progress -t "not @wip"'
  end

  desc 'Executar testes por tag'
  task :exec_tag, [:tag] do |_t, args|
    sh "bundle exec cucumber BROWSER=cuprite ENVIRONMENT_TYPE=local --format pretty -t @#{args[:tag]}"
  end

  desc 'Executar feature de exemplo'
  task :exec_example do
    sh 'bundle exec cucumber ENVIRONMENT_TYPE=local BROWSER=cuprite --format pretty -t @exemplo'
  end
end

namespace :ai do
  desc 'Executar specs unitários do SelfHealing'
  task :spec do
    sh "bundle exec ruby -I#{File.expand_path('features/support/self_healing/spec')} -e \"Dir['features/support/self_healing/spec/**/*_spec.rb'].each { |f| require File.expand_path(f) }\""
  end

  desc 'Executar instrução em linguagem natural via SelfHealing Agent (sem step definitions do Cucumber)'
  task :run, [:instruction] do |_t, args|
    ENV['SELF_HEALING_ENABLED'] = 'true'
    ENV['RAG_ENABLED'] = 'true'
    ENV['RAG_TOP_K'] ||= '3'
    ENV['RAG_MIN_SIMILARITY'] ||= '0.0'
    ENV['RAG_KNOWLEDGE_BASE_DIR'] ||= 'features/pages'
    ENV['ENVIRONMENT_TYPE'] ||= 'local'

    require_relative 'features/support/env'

    instruction = args[:instruction]
    if instruction.nil? || instruction.empty?
      raise 'Informe a instrução: rake ai:run["fazer login com standard_user"]'
    end

    Capybara.current_session.visit(CONFIG['url_home'])

    agent = SelfHealing::Agent.new
    result = agent.execute(instruction)

    puts "Resultado: #{result}"
  end

  desc 'Executar cenários de features .feature via SelfHealing Agent (sem step definitions do Cucumber)'
  task :run_features, [:tag, :features_dir] do |_t, args|
    ENV['SELF_HEALING_ENABLED'] = 'true'
    ENV['RAG_ENABLED'] = 'true'
    ENV['RAG_TOP_K'] ||= '3'
    ENV['RAG_MIN_SIMILARITY'] ||= '0.0'
    ENV['RAG_KNOWLEDGE_BASE_DIR'] ||= 'features/pages'
    ENV['ENVIRONMENT_TYPE'] ||= 'local'
    ENV['CUCUMBER_RUN'] = 'false'

    require_relative 'features/support/env'
    require_relative 'features/support/self_healing/feature_reader'
    require_relative 'features/support/self_healing/tools'

    tag = args[:tag]
    features_dir = args[:features_dir] || 'features/specs/self_healing'

    reader = SelfHealing::FeatureReader.new(features_dir: features_dir)
    scenarios = tag ? reader.scenarios_with_tag(tag) : reader.scenarios

    if scenarios.empty?
      puts "Nenhum cenário encontrado em '#{features_dir}'#{tag ? " com tag #{tag}" : ''}."
      next
    end

    Capybara.current_session.visit(CONFIG['url_home'])
    agent = SelfHealing::Agent.new
    failures = []

    scenarios.each do |scenario|
      puts "\nExecutando: #{scenario.name} (#{scenario.file}:#{scenario.line})"
      instruction = scenario.steps.join('. ')

      begin
        result = agent.execute(instruction)
        puts "Resultado: #{result}"
      rescue StandardError => e
        puts "Falha: #{e.class}: #{e.message}"
        puts e.backtrace.first(10).join("\n")
        failures << { scenario: scenario, error: e }
      end
    end

    puts "\n#{scenarios.size - failures.size}/#{scenarios.size} cenários executados com sucesso."
    exit(1) unless failures.empty?
  end

  desc 'Aplicar correções de locators do Self Healing nos arquivos de page objects'
  task :apply_corrections do
    require_relative 'features/support/env'
    require_relative 'features/support/self_healing/locator_applier'

    applier = SelfHealing::LocatorApplier.new
    results = applier.apply_all

    applied = results.select { |r| r[:status] == :applied }
    skipped = results.select { |r| r[:status] == :skipped }
    not_found = results.select { |r| r[:status] == :not_found }

    puts "\nCorreções aplicadas: #{applied.size}"
    applied.each do |r|
      puts "  - #{r[:page_object]}##{r[:element_name]} -> #{r[:new_locator]} (#{r[:file]})"
    end

    puts "\nIgnoradas (arquivo não encontrado): #{skipped.size}" unless skipped.empty?
    puts "Ignoradas (elemento não encontrado): #{not_found.size}" unless not_found.empty?

    exit(1) unless not_found.empty? && skipped.empty?
  end
end
