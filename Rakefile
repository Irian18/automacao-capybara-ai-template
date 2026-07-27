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

namespace :self_healing do
  desc 'Executar specs unitários do SelfHealing'
  task :spec do
    sh "bundle exec ruby -I#{File.expand_path('features/support/self_healing/spec')} -e \"Dir['features/support/self_healing/spec/*_spec.rb'].each { |f| require File.expand_path(f) }\""
  end
end
