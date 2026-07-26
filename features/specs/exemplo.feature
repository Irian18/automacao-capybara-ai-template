# language: pt
@exemplo
Funcionalidade: Exemplo de fluxo de login

  Cenário: Login com sucesso
    Dado que acessei a página de login
    Quando faço login com "usuario@exemplo.com" e "senha"
    Então devo ser redirecionado para a página inicial