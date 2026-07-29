# Self Healing

Este diretório contém o framework de Self Healing e RAG do projeto.

## Estrutura

```text
features/support/self_healing/
├── config/              # Configurações imutáveis
│   ├── config.rb
│   └── design_system.yml
├── rag/                 # Componentes do RAG (Retrieval-Augmented Generation)
│   ├── document.rb
│   ├── embedder.rb
│   ├── knowledge_base.rb
│   ├── retriever.rb
│   └── store.rb
├── tools/               # Ferramentas disponíveis para o agente
│   ├── assert_element.rb
│   ├── assert_text.rb
│   ├── click.rb
│   ├── fill_in.rb
│   ├── finish.rb
│   ├── generate_page_object.rb
│   ├── inspect_page.rb
│   ├── page_object_call.rb
│   ├── select_option.rb
│   ├── visit.rb
│   └── ...
├── prompts/             # Templates de prompts (imutáveis)
│   ├── heal.md.erb
│   ├── page_object_design_system.md
│   ├── siteprism_generator.md.erb
│   └── system.md.erb
├── knowledge_base/      # Base de conhecimento indexada pelo RAG
├── spec/                # Testes unitários
├── *.rb                 # Código de uso geral do Self Healing
│   ├── agent.rb
│   ├── agent_context.rb
│   ├── api_client.rb
│   ├── conversation.rb
│   ├── design_system.rb
│   ├── feature_reader.rb
│   ├── locator_applier.rb
│   ├── locator_history.rb
│   ├── page_object_generator.rb
│   ├── plan_cache.rb
│   ├── plan_executor.rb
│   ├── prompt_loader.rb
│   ├── rag.rb
│   ├── snapshot.rb
│   ├── tagged_scenario_runner.rb
│   └── tools.rb
└── locator_history.json # Histórico de locators gerado em runtime
```

## Convenções

- **Configuração imutável**: `config/`, `prompts/`, `knowledge_base/`.
- **Código de uso geral**: todos os `.rb` na raiz, `rag/` e `tools/`.
- **Dados gerados**: `locator_history.json`.
- **Testes**: `spec/`.

## Ponto de entrada

O arquivo `agent.rb` é o orquestrador principal, carregado por `features/support/env.rb` quando `SELF_HEALING_ENABLED=true` e pelas rake tasks.

## Processo de execução

### Self Healing — ciclo RECORD / REPLAY / HEAL

```
┌─────────────────────────────────────────────────────────────────────────┐
│ 1. CARGA                                                                │
│    - env.rb carrega `agent.rb` quando `SELF_HEALING_ENABLED=true`       │
│    - O cenário cria uma instância de `SelfHealing::Agent`               │
│    - O agente recebe o contexto atual (snapshot da página, PO, etc.)    │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 2. EXECUÇÃO DA INSTRUÇÃO                                                │
│    - `agent.execute("<instrução em linguagem natural>")` é chamado      │
│    - O agente consulta o `PlanCache` para ver se já existe plano        │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 3. MODO RECORD (plano ainda não existe ou AI_FORCE_RECORD=true)         │
│    - O agente tira um snapshot do HTML atual                            │
│    - Se RAG estiver ativo, recupera contexto dos Page Objects reais     │
│    - Envia prompt para a LLM com a instrução + snapshot + contexto      │
│    - A LLM responde com uma sequência de chamadas de ferramentas        │
│    - O agente executa cada ferramenta (click, fill_in, assert, etc.)    │
│    - Se tudo passar, o plano é salvo em `PlanCache`                     │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 4. MODO REPLAY (plano já existe e é válido)                             │
│    - O plano cacheado é carregado sem chamada à LLM                     │
│    - As ferramentas são executadas na ordem gravada                     │
│    - Rápido e sem custo de API                                          │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 5. MODO HEAL (REPLAY falhou)                                            │
│    - A ferramenta quebrada é identificada                               │
│    - Um novo snapshot é tirado                                          │
│    - Apenas o passo quebrado é enviado à LLM para correção              │
│    - O plano cacheado é atualizado com a correção                       │
└─────────────────────────────────────────────────────────────────────────┘
```

### RAG — ciclo de indexação e recuperação

```
┌─────────────────────────────────────────────────────────────────────────┐
│ 1. INICIALIZAÇÃO                                                        │
│    - `RAG_ENABLED=true` carrega `rag.rb`                                │
│    - `RAG_KNOWLEDGE_BASE_DIR` define os diretórios de conhecimento      │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 2. INDEXAÇÃO                                                            │
│    - `KnowledgeBase` escaneia `features/pages` e `knowledge_base/`      │
│    - Cada arquivo compatível vira um `Document`                         │
│    - `Embedder` gera vetores e `Store` persiste em `rag_store/`         │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 3. RECUPERAÇÃO                                                          │
│    - A instrução do agente é convertida em vetor                        │
│    - `Retriever` busca os `RAG_TOP_K` documentos mais similares         │
│    - Resultados acima de `RAG_MIN_SIMILARITY` são incluídos no prompt   │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 4. USO PELO AGENTE                                                      │
│    - O contexto recuperado é injetado no prompt de RECORD/HEAL          │
│    - A LLM gera seletores e ações alinhados aos POs reais do projeto    │
└─────────────────────────────────────────────────────────────────────────┘
```

### Execução via rake tasks

```bash
# Executar uma instrução diretamente
bundle exec rake self_healing:run["Preencha o formulário de login"]

# Executar cenários de arquivos .feature
bundle exec rake self_healing:run_features

# Forçar re-descoberta (ignora planos cacheados)
AI_FORCE_RECORD=true bundle exec rake self_healing:run_features
```
