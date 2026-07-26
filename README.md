# Automação E2E — Template Genérico

Template de automação de testes end-to-end (E2E) com **Ruby, Cucumber, Capybara, SitePrism e Cuprite**.

Inclui uma camada de **Self Healing Locators** e geração de Page Objects assistida por IA (LLM), pronta para ser adaptada a qualquer aplicação web.

---

## 🚀 Tecnologias

| Tecnologia | Versão | Descrição |
|------------|--------|-----------|
| [Ruby](https://www.ruby-lang.org/) | 3.3.5 | Linguagem de programação |
| [Cucumber](https://cucumber.io/) | 9.2.0 | Framework BDD |
| [Capybara](https://teamcapybara.github.io/capybara/) | 3.40.0 | Automação de interface web |
| [SitePrism](https://site-prism.readthedocs.io/) | 5.0 | Page Object Model |
| [Selenium WebDriver](https://www.selenium.dev/) | 4.18.0 | Driver para browsers |
| [Cuprite](https://github.com/rubycdp/cuprite) | - | Driver headless Chrome |
| [HTTParty](https://github.com/jnunemaker/httparty) | - | Requisições HTTP para API |
| [Allure](https://docs.qameta.io/allure/) | 2.0 | Relatórios |
| [ruby-openai](https://github.com/alexrudall/ruby-openai) | - | Cliente para APIs de LLM |
| [Faker](https://github.com/faker-ruby/faker) | - | Dados fake |
| [Dry::Struct](https://dry-rb.org/gems/dry-struct/) | - | Tipagem de models |

---

## 📋 Pré-requisitos

- **Ruby** 3.3.5+ (recomendado [asdf](https://asdf-vm.com/) ou [rbenv](https://github.com/rbenv/rbenv))
- **Bundler** (`gem install bundler`)
- **Google Chrome** (para execução com Cuprite)
- **Node.js** (para o Allure CLI)

---

## 🔧 Instalação

```bash
git clone <url-do-repositorio>
cd automacao-e2e
bundle install
```

Instale o Allure CLI (opcional, para relatórios):

```bash
npm install -g allure-commandline
```

---

## ⚙️ Configuração

1. Copie o exemplo de ambiente:

```bash
cp features/support/environments/example.yml features/support/environments/local.yml
```

2. Edite `features/support/environments/local.yml` com a URL da sua aplicação, credenciais e demais configurações.

3. Copie o `.env` de exemplo:

```bash
cp .env.example .env
```

4. Se for usar o Self Healing com IA, configure a chave no `.env`:

```bash
AI_API_KEY=sua-chave-aqui
```

---

## ▶️ Como Executar

```bash
# Ambiente padrão
bundle exec cucumber

# Ambiente específico
bundle exec cucumber -p local

# Por tag
bundle exec cucumber -t @login

# Feature específica
bundle exec cucumber features/specs/exemplo.feature
```

---

## 🏗️ Estrutura do Projeto

```
automation-e2e/
├── features/
│   ├── config/                  # Configurações de rotas (opcional)
│   ├── lib/api/                 # Classes de integração com APIs
│   ├── models/                  # Models tipados com Dry::Struct
│   ├── pages/                   # Page Objects com SitePrism
│   ├── services/                # Camada de serviços/negócio
│   ├── specs/                   # Arquivos .feature (BDD)
│   ├── step_definitions/        # Implementação dos steps
│   └── support/                 # Configurações e suporte
│       ├── self_healing/        # Self Healing + Geração de PO via IA
│       ├── environments/        # Configurações por ambiente
│       └── helpers/             # Helpers genéricos
├── report/                      # Relatórios gerados
├── .gitlab-ci.yml.exemple       # Exemplo de pipeline CI/CD
├── cucumber.yml                 # Perfis do Cucumber
├── Gemfile                      # Dependências Ruby
└── Rakefile                     # Tarefas Rake
```

---

## 🤖 Self Healing Locators + Geração de Page Objects

A camada `features/support/self_healing/` fornece:

1. **Self Healing Locators**
   - `RECORD` — IA descobre a sequência de interações e grava um plano cacheado
   - `REPLAY` — Executa o plano salvo sem custo de API
   - `HEAL` — Se a UI mudar, a IA corrige apenas o trecho quebrado

2. **Geração de Page Objects**
   - `SelfHealing::PageObjectGenerator` — gera Page Objects SitePrism via IA a partir do HTML

```ruby
agent = SelfHealing::Agent.new(page_object: @page)
agent.execute("Faça login com usuário 'admin' e senha 'secret'")
```

Documentação completa: [`features/support/self_healing/README.md`](features/support/self_healing/README.md)

---

## 🛠️ Comandos Úteis

```bash
# Executar com tag
bundle exec cucumber -t @exemplo

# Forçar re-descoberta de planos da IA
AI_FORCE_RECORD=true bundle exec cucumber features/specs/exemplo.feature

# Rubocop
bundle exec rubocop
bundle exec rubocop -a
```

---

## 📝 Convenções de Código

- **Features:** `nome_da_feature.feature`
- **Steps:** `nome_steps.rb`
- **Pages:** `nome_da_pagina_page.rb`
- **Services:** `nome_do_service.rb`

### Tags sugeridas

- `@issue:XXX` — vinculação com issue/ticket
- `@login` — executa login antes do cenário
- `@teardown` — limpa dados após o cenário
- `@wip` — work in progress (não executa em CI)

---

## 🤝 Contribuição

1. Crie uma branch a partir da `main`
2. Siga as convenções do projeto
3. Execute o Rubocop antes de submeter
4. Crie um Pull Request descrevendo as alterações

---

## 📄 Licença

Uso livre para adaptação em projetos de automação de testes.
