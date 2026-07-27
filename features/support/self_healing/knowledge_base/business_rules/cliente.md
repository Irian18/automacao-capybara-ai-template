# Regras de Negócio — Cadastro de Cliente

## Contexto

O cadastro de cliente é o fluxo inicial do CRM. Um cliente pode ser pessoa física (PF) ou pessoa jurídica (PJ). O sistema deve garantir unicidade por CPF/CNPJ e por e-mail.

---

## Regras obrigatórias

### Pessoa Física (PF)

- **CPF**: obrigatório, 11 dígitos numéricos, válido segundo algoritmo dos dígitos verificadores.
- **Nome completo**: obrigatório, mínimo 3 caracteres, máximo 150 caracteres.
- **Data de nascimento**: obrigatória, cliente deve ter pelo menos 18 anos.
- **E-mail**: obrigatório, formato válido e único no sistema.
- **Telefone**: obrigatório, DDD + 9 dígitos (ex: 11999998888).
- **Gênero**: opcional (Masculino, Feminino, Não informar).

### Pessoa Jurídica (PJ)

- **CNPJ**: obrigatório, 14 dígitos numéricos, válido.
- **Razão social**: obrigatória, mínimo 3 caracteres.
- **Nome fantasia**: opcional.
- **E-mail corporativo**: obrigatório, único.
- **Telefone comercial**: obrigatório, DDD + 9 dígitos.

---

## Comportamento do formulário

- O botão **"Salvar"** permanece desabilitado enquanto houver erros de validação.
- Campos inválidos devem exibir mensagem de erro em vermelho abaixo do campo.
- Ao clicar em **"Salvar"** com sucesso:
  - O sistema exibe um modal com a mensagem: `"Cliente cadastrado com sucesso"`.
  - O cliente recebe um e-mail de boas-vindas.
  - O usuário é redirecionado para a tela de detalhes do cliente.
- Ao clicar em **"Cancelar"**, o sistema pergunta se deseja descartar as alterações.

---

## Fluxo padrão de cadastro PF

1. Acesse a rota `/clients/register`.
2. Selecione o tipo "Pessoa Física".
3. Preencha:
   - CPF: `529.982.247-25`
   - Nome: `Maria da Silva`
   - Data de nascimento: `15/03/1990`
   - E-mail: `maria.silva@exemplo.com`
   - Telefone: `(11) 99999-8888`
4. Clique em "Salvar".
5. Valide o modal de sucesso.
6. Valide o redirecionamento para `/clients/12345/details`.

---

## Fluxo alternativo: CPF já cadastrado

1. Acesse `/clients/register`.
2. Preencha o CPF `529.982.247-25` (já existente).
3. Saia do campo (blur).
4. O sistema exibe a mensagem: `"CPF já cadastrado no sistema"`.
5. O botão "Salvar" permanece desabilitado.

---

## Mensagens de erro esperadas

| Cenário | Mensagem esperada |
|---|---|
| CPF inválido | `"CPF informado é inválido"` |
| CPF já cadastrado | `"CPF já cadastrado no sistema"` |
| E-mail inválido | `"Formato de e-mail inválido"` |
| E-mail duplicado | `"E-mail já cadastrado no sistema"` |
| Telefone inválido | `"Telefone deve conter DDD + 9 dígitos"` |
| Menor de idade | `"Cliente deve ter pelo menos 18 anos"` |
| Campo obrigatório vazio | `"Campo obrigatório"` |

---

## Dados de teste válidos

```text
CPF:        529.982.247-25
Nome:       Maria da Silva
Nascimento: 15/03/1990
E-mail:     maria.silva@exemplo.com
Telefone:   (11) 99999-8888