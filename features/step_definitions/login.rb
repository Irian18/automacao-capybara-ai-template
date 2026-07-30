Dado('que acessei a página de login') do
  login.load
end

Quando('faço login com usuário {string} e senha {string}') do |usuario, senha|
  login.logar_usuario(usuario, senha)
end

Então('devo ver uma mensagem de erro {string} indicando que o usuário está bloqueado') do |mensagem|
  expect(login.msg_error_containet).to have_text(mensagem)
end

Então('devo ser redirecionado para a página inicial com url {string} com nome {string}') do |url, nome|
  expect(page).to have_current_path("/#{url}") 
  expect(products.secondary_header.span_title).to have_text(nome)
end
