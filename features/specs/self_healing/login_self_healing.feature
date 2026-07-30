# language: pt
@wip

@login-self-healing
Funcionalidade: Exemplo de fluxo de login - Usuário não cadastrado

  Cenário: Usuário não cadastrado
    Dado que acessei a página de login
    Quando faço login com usuário "usuario_invalido" e senha "senha_invalida"
    Então devo ver uma mensagem de erro "Epic sadface: Username and password do not match any user in this service" indicando que o usuário não está cadastrado