require_relative '../support/self_healing/agent'

Quando('faço login com credenciais válidas usando RAG') do
  agent = SelfHealing::Agent.new(
    session: Capybara.current_session,
    logger: Logger.new($stdout)
  )

  # A instrução é genérica. O RAG recuperará as credenciais e seletores da knowledge base.
  agent.execute('Faça login com as credenciais válidas do sistema')
end

Então('devo ver a página inicial') do
  expect(page).to have_selector('[data-test-id="welcome-message"]', text: 'Bem-vindo à página inicial')
end
