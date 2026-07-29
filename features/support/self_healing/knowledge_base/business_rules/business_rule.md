# Regras de Negócio — Login do Sistema Ecommerce Swag Labs

## Contexto

Para realizer o login existe usuários já cadastrados:
Accepted usernames are:
standard_user
locked_out_user
problem_user
performance_glitch_user
error_user
visual_user

Password for all users:
secret_sauce

---

## Regras do Login - Username

- **standard_user**: 
  - Usuário padrão para realizar compras normalmente
- **locked_out_user**: 
  - Usuário bloqueado, ao realizar o login vai ser demonstrado a mensagem: `"Epic sadface: Sorry, this user has been locked out."`.
- **problem_user**:
  - Usuário com problemas, ao realizar o login o sistema as imagens dos produtos são igual entre si da tela **Products**, o campo  e **FirstName** e **LastName** não funcionam da tela **Checkout: Your Information**.
- **performance_glitch_user**:
  - Usuário com problema de performance, ao realizar o login o sistema fica mais lento para carregar as ordenações dos produtos da tela **Products** e trocas de telas.
- **error_user**: 
  - Ao realizar o login com esse usuário, não é mais possível adicionais mais do que 3 produtos ao carrinho de compras, não é possivel reaizar a ordenção (tela **Products**), não é possível remover um produto do carrinho de compras (tela **Products**), o campo **LastName** não funciona da tela **Checkout: Your Information**    
- **visual_user**: 
  - Ao realizar o login com esse usuário os componentes do sistema ficam desalinhado.

## Regras do Login - Password

- **secret_sauce**:
  - Senha padrão para todos os usuários


### Telas do Sistema Ecommerce Swag Labs

- **Swag Labs**: dominio `https://www.saucedemo.com` sem rota
- **Products**: rota `/inventory.html`
- **Your Cart**: rota `/cart.html`
- **Checkout: Your Information**: `rota /checkout-step-one.html`
- **Checkout: Overview**: rota `/checkout-step-two.html`
- **Checkout: Complete!**: rota `/checkout-complete.html`

---

## Campos de cada Tela.
- **Swag Labs**: É o login, tem os campos **Username**, **Password**, botão de **Login**.
  - Campo **Username** é obrigatório, caso deixar o campo em branco vai demonstrar a mensagem `"Epic sadface: Username is required"`.
  - Campo **Password** é obrigatório, caso deixar o campo em branco vai demonstrar a mensagem `"Epic sadface: Password is required"`.
  - Informando **Username** e **Password** incorretos, é demonstrado a mensagem `"Epic sadface: Username and password do not match any user in this service"`.
- **Products**: É demonstrado todos os produtos do sistema, pelo Menu o acesso é em **All Items**.
  - Cada Produto em um Título, Descrição e Valor. Tem Botão **Add to cart** para adicionar o produto ao carrinho de compras e o botão **Remove** para remover o produto do carrinho de compras.
  - Tem um botão para realizar a ordenção por: **Name (A to Z)**, **Name (Z to A)**, **Price (low to high)** e **Price (high to low)**
  - Botão de carrinho de compra que redireciona para  `/cart.html`, quando adicionado produtos ao carrinho no botão é demonstrado a quantidade de iten.
- **Your Cart**: Demonstra todos os produtos que foram adicionados ao carrinho de compras, o acesso é pela tela **Products**.
  - Cada produto tem os campos de Título, Descrição, Valor e o botão **Remove** para remover o produto do carrinho de compras.
  - Botão **Checkout** que redireciona para a tela **Checkout: Your Information** rota `/checkout-step-one.html`.
- **Checkout: Your Information** Tela para informar as informações de Checkout.
  - Campo **FirstName** é informado o primeiro nome do comprador. Campo esse que é obrigatório, caso não informar valor é demonstrado a mensagem `Error: First Name is required`.
  - Campo **LastName** é informado o último nome do comprador. Campo esse que é obrigatório, caso não informar valor é demonstrado a mensagem `Error: Last Name is requiredd`.
  - Campo **Zip/Postal Code** é informado ocódigo postal do comprador. Campo esse que é obrigatório, caso não informar valor é demonstrado a mensagem `Error: Postal Code is required`.
  - Botão **Continue** que redireciona parar a tela **Checkout: Overview** rota `/checkout-step-two.html`
   - Botão **Cancel** que redireciona parar a tela **Your Cart** rota `/cart.html`
- **Checkout: Overview** Tela é demonstrados quais produtos foram comprados.
- **Checkout: Complete!** Tela fina, com botão **Back Home** que redireciona para a tela **Products** rota /inventory.html

---

## Fluxo padrão de compra de produto

1. Acesse a rota `/inventory.html`.
2. Adicione ao carrinho alguns produtos.
3. Clique no carrinho de compra, rota `/cart.html`
4. Clique no botão `Checkout`
5. Preencha:
   - First Name: `Maria `
   - Last Name: `Silva`
   - Zip/Posta Code: `85905-680`
6. Clique em "Continue".
7. Clique em "Finish"
