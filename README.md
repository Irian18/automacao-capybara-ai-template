# Automação E2E — Template Genérico

Template de automação de testes end-to-end (E2E) com **Ruby, Cucumber, Capybara, SitePrism e Cuprite**.

Inclui uma camada opcional de **Self Healing Locators** e geração de Page Objects assistida por IA (LLM), pronta para ser adaptada a qualquer aplicação web.

> **Por padrão, Self Healing e RAG estão desabilitados.** Eles só são carregados quando os perfis `self_healing` e/ou `rag` são informados.

---

## 🚀 Tecnologias

| Tecnologia | Versão | Descrição |
|------------|--------|-----------|
| [Ruby](https://www.ruby-lang.org/) | 3.3.x | Linguagem de programação |
| [Cucumber](https://cucumber.io/) | ~9.2.0 | Framework BDD |
| [Capybara](https://teamcapybara.github.io/capybara/) | ~3.40.0 | Automação de interface web |
| [SitePrism](https://site-prism.readthedocs.io/) | ~5.0 | Page Object Model |
| [Selenium WebDriver](https://www.selenium.dev/) | ~4.18.0 | Driver para browsers |
| [selenium-devtools](https://github.com/SeleniumHQ/selenium/tree/trunk/rb) | ~0.132.0 | Protocolo DevTools para Selenium |
| [Cuprite](https://github.com/rubycdp/cuprite) | - | Driver headless Chrome via CDP |
| [Ferrum](https://github.com/rubycdp/ferrum) | - | Browser CDP usado pelo Cuprite |
| [HTTParty](https://github.com/jnunemaker/httparty) | - | Requisições HTTP para API |
| [Allure](https://docs.qameta.io/allure/) | ~2.0 | Relatórios |
| [ruby-openai](https://github.com/alexrudall/ruby-openai) | - | Cliente para APIs de LLM |
| [Faker](https://github.com/faker-ruby/faker) | - | Dados fake |
| [Dry::Struct](https://dry-rb.org/gems/dry-struct/) | - | Tipagem de models |
| [dotenv](https://github.com/bkeepers/dotenv) | ~3.0 | Carrega variáveis do `.env` |

---

## 📋 Pré-requisitos

- **Ruby** 3.3.x (recomendado [asdf](https://asdf-vm.com/) ou [rbenv](https://github.com/rbenv/rbenv))
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

1. Copie o `.env` de exemplo:

```bash
cp .env.example .env
```

2. Se for usar o Self Healing com IA, configure a chave no `.env`:

```bash
AI_API_KEY=sua-chave-aqui
```

3. Configure o ambiente de teste:

O projeto já vem com `features/support/environments/example.yml`. O perfil `default` do Cucumber usa esse arquivo. Você pode editá-lo diretamente ou criar um novo ambiente (ex: `local.yml`, `staging.yml`) e executar com o perfil correspondente.

```bash
# Usar o ambiente example padrão (não precisa passar perfil)
bundle exec cucumber

# Usar um ambiente específico
bundle exec cucumber -p local
```

---

## ▶️ Como Executar

```bash
# Ambiente padrão (Self Healing e RAG desabilitados)
bundle exec cucumber

# Ambiente específico
bundle exec cucumber -p local

# Por tag
bundle exec cucumber -t @exemplo

# Feature específica
bundle exec cucumber features/specs/exemplo.feature

# Com Self Healing habilitado
bundle exec cucumber -p self_healing features/specs/self_healing/login_self_healing.feature

# Com Self Healing + RAG habilitados
bundle exec cucumber -p self_healing -p rag features/specs/self_healing/login_self_healing.feature
```

---

## 📁 cucumber.yml e Perfis de Execução

O arquivo [`cucumber.yml`](cucumber.yml) centraliza os **perfis** do Cucumber, combinando formatação, ambiente, relatórios e drivers em um único lugar.

| Perfil | Descrição |
|--------|-----------|
| `default` | Perfil ativado automaticamente. Combina `pretty`, `example`, `allure`, `routes_name`, `local`, `cuprite`, `norag`, `no_self_healing` e exclui cenários `@wip`. |
| `pretty` / `for_ci` | Formatação do console (`pretty` para local, `progress` para CI). |
| `example` / `local` / `staging` / `sandbox` / `prod` / `prod_automacao_ci` | Define o `ENVIRONMENT_TYPE` correspondente. |
| `allure` / `html` / `json` | Gera relatórios nos formatos indicados. |
| `cuprite` | Define `BROWSER=cuprite`. |
| `routes_name` | Carrega `ROUTES_NAME=features/config/routes_by_name.yml`. |
| `rag` / `norag` | Ativa ou desativa o RAG. O profile `rag` usa `features/pages` como base de conhecimento. |
| `self_healing` / `no_self_healing` | Ativa ou desativa o carregamento da camada Self Healing. |

### ENVIRONMENT_TYPE

A variável `ENVIRONMENT_TYPE` indica qual arquivo de configuração de ambiente será carregado em `features/support/environments/<ENVIRONMENT_TYPE>.yml`. Ela é definida pelo perfil escolhido no `cucumber.yml`:

```bash
bundle exec cucumber -p staging   # ENVIRONMENT_TYPE=staging
bundle exec cucumber -p prod      # ENVIRONMENT_TYPE=prod
```

Isso permite alternar rapidamente entre ambientes (local, staging, produção etc.) sem alterar código.

---

## 🏗️ Estrutura do Projeto

```
automation-e2e/
├── features/
│   ├── config/                  # Configurações de rotas e mapeamentos
│   │   └── routes_by_name.yml   # Mapeamento de rotas para nomes de página
│   ├── lib/api/                 # Classes de integração com APIs
│   ├── models/                  # Models tipados com Dry::Struct
│   ├── pages/                   # Page Objects reais com SitePrism
│   │   ├── login/
│   │   ├── products/
│   │   ├── checkouts/
│   │   ├── your_cart/
│   │   └── section/             # Seções compartilhadas (header, footer)
│   ├── services/                # Camada de serviços/negócio
│   ├── specs/                   # Arquivos .feature (BDD)
│   │   └── self_healing/        # Cenários que usam o agente de Self Healing
│   ├── step_definitions/        # Implementação dos steps
│   └── support/                 # Configurações e suporte
│       ├── self_healing/        # Self Healing + Geração de PO via IA
│       ├── environments/        # Configurações por ambiente
│       ├── helpers/             # Helpers genéricos
│       ├── page_helper.rb       # Instancia os Page Objects disponíveis no World
│       └── env.rb               # Configuração do Capybara, Allure e hooks
├── report/                      # Relatórios gerados
├── tmp/                         # Arquivos temporários, cache e screenshots
├── .gitlab-ci.yml.exemple       # Exemplo de pipeline CI/CD
├── cucumber.yml                 # Perfis do Cucumber
├── Gemfile                      # Dependências Ruby
└── Rakefile                     # Tarefas Rake
```

---

## 🧩 Page Helper

O arquivo [`features/support/page_helper.rb`](features/support/page_helper.rb) carrega todos os Page Objects de `features/pages` e expõe métodos helper no `World` do Cucumber.

```ruby
module Pages
  def login
    @login ||= LoginPage.new
  end
end
```

Dentro dos steps você pode usar diretamente:

```ruby
login.fill_credentials('standard_user', 'secret_sauce')
```

Para adicionar uma nova página:

1. Crie o arquivo em `features/pages/<dominio>/<nome>_page.rb`.
2. Adicione o método helper em `features/support/page_helper.rb`.

---

## 🤖 Self Healing Locators + Geração de Page Objects

A camada `features/support/self_healing/` fornece:

1. **Self Healing Locators**
   - `RECORD` — IA descobre a sequência de interações e grava um plano cacheado
   - `REPLAY` — Executa o plano salvo sem custo de API
   - `HEAL` — Se a UI mudar, a IA corrige apenas o trecho quebrado

2. **Geração de Page Objects**
   - `SelfHealing::PageObjectGenerator` — gera Page Objects SitePrism via IA a partir do HTML

3. **Leitura de Features**
   - [`SelfHealing::FeatureReader`](features/support/self_healing/feature_reader.rb) — lê arquivos `.feature` e extrai cenários, tags e steps. É usado internamente pelo runner de cenários para descobrir e executar testes de self healing de forma automatizada.

4. **RAG Knowledge Base**
   - Os Page Objects reais em [`features/pages/`](features/pages/) são usados como base de conhecimento para o RAG. Dessa forma, a IA mantém o mesmo padrão, nomenclatura e estilo do projeto ao gerar novos POs ou corrigir planos.
   - Documentos extras podem ser mantidos em [`knowledge_base/`](features/support/self_healing/knowledge_base/) (`.md`, `.txt`, `.yml`, `.feature`) para regras de negócio, fluxos e validações. Veja [`knowledge_base/README.md`](features/support/self_healing/knowledge_base/README.md) para detalhes.


### Prompts do agente

A pasta `features/support/self_healing/prompts/` contém os templates de prompt usados pela IA:

| Arquivo | Papel |
|---------|-------|
| `system.md.erb` | Manual geral do agente: estratégia de seletores, ferramentas disponíveis, tom das respostas e regras genéricas de automação. |
| `page_object_design_system.md` | Diretrizes de design system para geração de Page Objects. |
| `siteprism_generator.md.erb` | Template usado pelo `PageObjectGenerator` para criar novos POs no padrão SitePrism. |
| `heal.md.erb` | Prompt usado no modo HEAL para corrigir apenas o passo quebrado. |

- Use `knowledge_base/business_rules/` quando quiser ensinar **o que** o agente deve testar.
   - Regras de negócio da aplicação;
   - Fluxos específicos;
   -  Mensagens de erro esperadas;
   - Validações de campos;
   - Dados de teste válidos.
- Use `system.md.erb` quando quiser mudar **como** o agente testa:
   - A estratégia de seletores (ex: priorizar data-testid);
   - As ferramentas disponíveis;
   - O tom ou formato das respostas;
   - Regras genéricas de automação.

```ruby
agent = SelfHealing::Agent.new(page_object: @page)
agent.execute("Faça login com usuário 'admin' e senha 'secret'")
```

---

### Relação entre Self Healing e RAG

| Perfil | O que habilita | Papel |
|--------|----------------|-------|
| `self_healing` | `SELF_HEALING_ENABLED=true` | Carrega o `SelfHealing::Agent` e permite executar instruções em linguagem natural (RECORD/REPLAY/HEAL). |
| `rag` | `RAG_ENABLED=true` + `RAG_KNOWLEDGE_BASE_DIR=features/pages` | Indexa os Page Objects reais do projeto e os injeta no prompt da IA como contexto extra. |

**O `rag` é um contexto adicional para o `self_healing`.** Você pode usar `self_healing` sozinho, mas se também usar `rag`, o agente consulta a base de conhecimento antes de gerar ou corrigir planos.

#### Comportamento por combinação

```
┌─────────────────┐     ┌─────────────────────────────┐
│  -p self_healing│     │  -p self_healing -p rag     │
└────────┬────────┘     └─────────────┬───────────────┘
         │                            │
         ▼                            ▼
┌─────────────────┐     ┌─────────────────────────────┐
│ env.rb carrega  │     │ env.rb carrega agent.rb     │
│   agent.rb      │     │ e RAG indexa features/pages │
└────────┬────────┘     └─────────────┬───────────────┘
         │                            │
         ▼                            ▼
┌─────────────────┐     ┌─────────────────────────────┐
│  IA usa apenas  │     │  IA usa snapshot + Page     │
│ snapshot + PO   │     │ Objects reais como contexto │
│  atual          │     │  no RECORD e no HEAL        │
└─────────────────┘     └─────────────────────────────┘
```

#### Quando usar cada combinação

| Combinação | Quando usar |
|------------|-------------|
| **Nenhum** (padrão) | Testes normais com Page Objects tradicionais. |
| **Apenas `self_healing`** | Quer usar IA para descobrir/corrigir ações, mas não quer depender de uma base de conhecimento. |
| **`self_healing` + `rag`** | Quer que a IA use os Page Objects reais do projeto como referência, gerando ações mais alinhadas ao padrão do time. |
| **Apenas `rag`** | Não tem efeito prático, pois o agente não é carregado. |

#### Exemplos de execução

```bash
# Testes normais — sem IA
bundle exec cucumber

# Self Healing sem RAG — IA descobre os seletores sozinha
bundle exec cucumber -p self_healing features/specs/self_healing/login_self_healing.feature

# Self Healing com RAG — IA usa os Page Objects reais como referência
bundle exec cucumber -p self_healing -p rag features/specs/rag_tutorial.feature
```

#### Exemplo no código

Com `self_healing` apenas, o step pede uma ação específica:

```ruby
# features/step_definitions/self_healing/login_self_healing_steps.rb
@agent.execute('Acesse a página de login')
@agent.execute("Preencha o campo de e-mail com '#{email}'")
```

Com `self_healing` + `rag`, a instrução pode ser mais genérica, porque a IA recupera os seletores e métodos dos Page Objects reais:

```ruby
# features/step_definitions/rag_tutorial_steps.rb
agent.execute('Faça login com as credenciais válidas do sistema')
```

Documentação completa da camada de Self Healing (modos de operação, configuração, RAG, retry adaptativo e execução automática de cenários) está em [`features/support/self_healing/README.md`](features/support/self_healing/README.md).

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
