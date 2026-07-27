# frozen_string_literal: true

require_relative '../../support/self_healing/agent'

Dado('que acessei a página de login') do
  @agent ||= SelfHealing::Agent.new(
    session: Capybara.current_session,
    logger: Logger.new($stdout)
  )

  @agent.execute('Acesse a página de login')
end

Quando('preencho o email com {string}') do |email|
  @agent.execute("Preencha o campo de e-mail com '#{email}'")
end

Quando('preencho a senha com {string}') do |senha|
  @agent.execute("Preencha o campo de senha com '#{senha}'")
end

Quando('clico no botão entrar') do
  @agent.execute('Clique no botão de entrar')
end

Então('devo ver a página inicial') do
  @agent.execute('Verifique que a página inicial está visível')
end
