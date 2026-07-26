# SelfHealing — Self Healing Locators + Geração de Page Objects

Camada de inteligência artificial genérica para automação E2E sobre **Capybara + Cuprite**.

Funcionalidades:

1. **Self Healing Locators** — quando um plano cacheado falha durante o REPLAY, a IA corrige apenas o passo quebrado e atualiza o cache.
2. **Geração de Page Objects** — geração de Page Objects SitePrism via IA (LLM) usando `SelfHealing::PageObjectGenerator`.

---

## Visão geral

```
execute(instruction)
       │
       ├─ cache existe? ──NÃO──► RECORD  → chama IA, grava plano, salva cache
       │
       └─ SIM ──────────────────► REPLAY → executa plano salvo
                                      │
                                      └─ passo falhou? ──► HEAL → IA corrige e
                                                                    atualiza cache
```

Cada instrução vira um **plano** (lista de tool calls) persistido em JSON. Nas execuções seguintes o plano roda sem custo de IA. Se a UI mudar e um passo quebrar, o modo **HEAL** aciona a IA apenas para o trecho necessário e regrava o cache.

---

## 1. `SelfHealing::Agent` — Orquestrador

**Arquivo:** `agent.rb`

A partir de agora o agente também pode usar **RAG (Retrieval-Augmented Generation)** para enriquecer o prompt com documentos relevantes da pasta `knowledge_base/`. Veja a seção [RAG](#rag-retrieval-augmented-generation).

Classe central que coordena RECORD/REPLAY/HEAL.

| Método | Descrição |
|--------|-----------|
| `initialize(session:, page_object:, logger:, cache:, helper:)` | Cria o agente. `session` padrão é `Capybara.current_session`. |
| `execute(instruction)` | Recebe uma instrução em linguagem natural e a executa. |
| `mode` | Retorna o modo usado na última execução: `:record`, `:replay` ou `:heal`. |

```ruby
agent = SelfHealing::Agent.new(page_object: @page)
agent.execute("Faça login com usuário 'admin' e senha 'secret'")
puts agent.mode  # => :record, :replay ou :heal
```

---

## 2. Modos de Operação

### RECORD — Descoberta
A IA analisa a página atual e gera uma sequência de tool calls. Ao final, o plano é salvo em cache.

```bash
AI_FORCE_RECORD=true bundle exec cucumber features/login.feature
```

### REPLAY — Execução sem custo
Recupera o plano do cache e executa passo a passo.

### HEAL — Auto-reparo
Se um passo do REPLAY falha, a IA é chamada **apenas para o trecho quebrado**, gera um novo plano corrigido e grava no cache.

---

## 3. `SelfHealing::Tools` — Ferramentas Genéricas

**Arquivo:** `tools.rb`

Todas as ferramentas são genéricas e funcionam em qualquer aplicação web:

| Tool | Função |
|------|--------|
| `inspect_page` | Snapshot dos elementos interativos |
| `visit` | Navega para URL |
| `click` | Clica por texto ou CSS |
| `fill_in` | Preenche input/textarea |
| `select_option` | Seleciona opção em `<select>` nativo |
| `assert_text` | Verifica texto visível |
| `assert_element` | Verifica elemento por CSS |
| `page_object_call` | Usa elemento mapeado na Page Object atual |
| `generate_page_object` | Gera PO via IA (LLM) — tem custo de API |
| `finish` / `fail_test` | Conclui ou aborta |

Cada tool de interação tem retry adaptativo automático (até 3 tentativas com waits de 1s, 2s, 4s).

---

## 4. `SelfHealing::PageObjectGenerator` — Geração de Page Objects com IA

**Arquivo:** `page_object_generator.rb`

Gera **Page Objects usando LLM** a partir do HTML da página atual. Tem custo de API.

```ruby
generator = SelfHealing::PageObjectGenerator.new(session: Capybara.current_session)
file_path = generator.generate("ClientRegisterPage", url: "/clients/register")

puts file_path # tmp/page_objects/generated/client_register_page.rb
```

Também pode ser invocado via agente:

```ruby
agent.execute("Gerar page object para esta página como ClientRegisterPage")
```

---

## 5. Configuração

**Arquivo:** `.env`

Copie o `.env.example` para `.env` e preencha suas chaves:

```bash
cp .env.example .env
```

```bash
# Self Healing / IA
AI_API_KEY=sua-chave-aqui
BASE_URL=https://api.moonshot.ai/v1
MODEL=kimi-k2.6
PO_MODEL=moonshot-v1-128k

# RAG
RAG_ENABLED=true
RAG_EMBEDDING_MODEL=text-embedding-3-small
RAG_EMBEDDING_API_KEY=sua-chave-aqui
RAG_EMBEDDING_BASE_URL=https://api.moonshot.ai/v1
RAG_TOP_K=3
RAG_MIN_SIMILARITY=0.0
```

**Arquivo:** `cucumber.yml`

Ambiente e browser ficam centralizados no `cucumber.yml`:

```yaml
local: ENVIRONMENT_TYPE=local
cuprite: BROWSER=cuprite
```

| Variável | Local | Descrição |
|----------|-------|-----------|
| `AI_API_KEY` | `.env` | Chave de API do serviço de IA (obrigatória) |
| `BASE_URL` | `.env` | Base URL da API |
| `MODEL` | `.env` | Modelo usado pelo agente (RECORD/HEAL) |
| `PO_MODEL` | `.env` | Modelo usado para geração de Page Objects |
| `RAG_ENABLED` | `.env` | Ativa/desativa o RAG |
| `RAG_EMBEDDING_MODEL` | `.env` | Modelo de embedding (OpenAI-compatible) |
| `RAG_EMBEDDING_API_KEY` | `.env` | Chave para embeddings |
| `RAG_EMBEDDING_BASE_URL` | `.env` | Base URL para embeddings |
| `RAG_TOP_K` | `.env` | Documentos recuperados por consulta |
| `RAG_MIN_SIMILARITY` | `.env` | Score mínimo para incluir documento |
| `ENVIRONMENT_TYPE` | `cucumber.yml` | Ambiente de teste |
| `BROWSER` | `cucumber.yml` | Browser de execução |

---

## 6. Adaptação para outros projetos

Copie o exemplo de configuração:

```bash
cp config/design_system.example.yml config/design_system.yml
```

Edite `config/design_system.yml` para ensinar o SelfHealing sobre os componentes da sua aplicação:

- `interactive_selectors`: seletores considerados interativos no snapshot
- `field_components`: componentes customizados que devem ser mapeados como campos
- `section_components`: componentes que definem seções de página
- `ignore_tags`: tags removidas durante parsing
- `unstable_id_patterns`: padrões de IDs instáveis a ignorar

Para componentes muito específicos, estenda `SelfHealing::Tools` com novas ferramentas no projeto consumidor.

---

## 7. RAG (Retrieval-Augmented Generation)

**Arquivos:** `rag/*.rb`

O RAG permite que o agente consulte uma base de conhecimento antes de executar uma instrução. Isso é útil para:

- Injetar regras de negócio da aplicação no prompt.
- Reutilizar Page Objects de referência na geração de novos POs.
- Recuperar fluxos e validações específicas do domínio.

### Como ativar

1. Crie a pasta `features/support/self_healing/knowledge_base/` e adicione documentos `.md`, `.txt`, `.yml`, `.rb` ou `.feature`.
2. Ative no `.env`:

```bash
RAG_ENABLED=true
```

### Configurações disponíveis

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `RAG_ENABLED` | `false` | Ativa/desativa o RAG |
| `RAG_KNOWLEDGE_BASE_DIR` | `knowledge_base/` | Pasta com documentos |
| `RAG_STORE_PATH` | `rag_store/` | Onde salvar índice e embeddings |
| `RAG_TOP_K` | `3` | Quantidade de documentos recuperados |
| `RAG_MIN_SIMILARITY` | `0.0` | Score mínimo para incluir um documento |
| `RAG_EMBEDDING_MODEL` | `text-embedding-3-small` | Modelo de embedding (API OpenAI-compatible) |
| `RAG_EMBEDDING_API_KEY` | `AI_API_KEY` | Chave para embeddings |
| `RAG_EMBEDDING_BASE_URL` | `BASE_URL` | Base URL para embeddings |

Se `RAG_EMBEDDING_MODEL` estiver vazio, o sistema usa um embedder local por palavras-chave (sem custo de API).

### Componentes

- `Rag::Document` — representa um documento vetorizado.
- `Rag::Embedder` — gera embeddings via API ou palavras-chave.
- `Rag::Store` — armazena documentos em JSON local.
- `Rag::Retriever` — busca documentos por similaridade de cosseno.
- `Rag::KnowledgeBase` — indexa arquivos da pasta `knowledge_base/`.

### Uso manual

```ruby
kb = SelfHealing::Rag::KnowledgeBase.new
kb.index!

retriever = SelfHealing::Rag::Retriever.new
puts retriever.context_for('como cadastrar um cliente')
```

---

## 9. Retry Adaptativo

Ferramentas de interação aplicam retry com backoff exponencial automático (1s, 2s, 4s) em erros de elemento não encontrado, reduzindo flakiness sem custo de API.

---

## 10. Execução automática de cenários em `features/specs/self_healing`

Além de chamar `agent.execute(instruction)` manualmente, é possível executar todos os cenários de `.feature` localizados em `features/specs/self_healing`.

```ruby
runner = SelfHealing::TaggedScenarioRunner.new(
  page_object: @page,
  cache: cache
)
results = runner.run

results.each do |r|
  puts "#{r.scenario} | #{r.step} | #{r.success ? 'OK' : 'FALHOU'} | modo: #{r.mode}"
end
```

O runner:
- Varre `features/specs/self_healing/**/*.feature` por padrão.
- Executa **todos os cenários** da pasta, independentemente de tag.
- Executa cada step como uma instrução independente no `SelfHealing::Agent`.
- Retorna uma lista de resultados com `file`, `line`, `scenario`, `step`, `success`, `mode` e `error`.

Para usar outra pasta:

```ruby
runner.run(features_dir: 'features/specs/outra_pasta')
```

A filtragem por tag ainda funciona quando necessária:

```ruby
SelfHealing::TaggedScenarioRunner.new(tag: '@ai', page_object: @page).run
```

---

## 11. Arquivos ignorados

Planos cacheados, snapshots e Page Objects gerados não devem ser commitados. O `.gitignore` já está configurado.
