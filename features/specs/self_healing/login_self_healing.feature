# language: pt
@self_healing @login
Funcionalidade: Login com SelfHealing

  Cenário: Login com sucesso usando instruções em linguagem natural
    Dado que acessei a página de login
    Quando preencho o email com "usuario@exemplo.com"
    E preencho a senha com "senha123"
    E clico no botão entrar
    Então devo ver a página inicial
