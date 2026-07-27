Dado('que acessei a página de login para debug') do
  visit("")
  binding.pry
end

Quando('faço login com {string} e {string}') do |email, senha|
  login.logar_usuario(email, senha)
end

Então('devo ser redirecionado para a página inicial') do
  expect(page).to have_current_path('/home', only_path: true)
end
