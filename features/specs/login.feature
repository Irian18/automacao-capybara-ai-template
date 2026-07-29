# language: pt
@login
Funcionalidade: Exemplo de fluxo de login

  Cenário: Login locked out
    Dado que acessei a página de login
    Quando faço login com usuário "locked_out_user" e senha "secret_sauce"
    Então devo ver uma mensagem de erro "Epic sadface: Sorry, this user has been locked out." indicando que o usuário está bloqueado

  Cenário: Login com sucesso
    Dado que acessei a página de login
    Quando faço login com usuário "standard_user" e senha "secret_sauce"
    Então devo ser redirecionado para a página inicial com url "inventory.html" com nome "Products"