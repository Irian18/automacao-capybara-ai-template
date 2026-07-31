# Knowledge Base — RAG do SelfHealing

Coloque aqui documentos que ajudem o agente a tomar decisões melhores.

> **Atenção:** os Page Objects usados como referência pelo RAG são os arquivos reais do projeto em [`features/pages/`](../../../pages/). Não mantenha arquivos `.rb` de Page Objects dentro desta pasta, pois eles podem conflitar com as classes já carregadas pelo `features/support/page_helper.rb`.

## Tipos de documentos suportados

- `.md` — documentação de funcionalidades, regras de negócio, fluxos
- `.txt` — anotações textuais
- `.yml` / `.yaml` — configurações específicas de domínio
- `.feature` — cenários Gherkin de referência

## Como funciona

1. Ao iniciar, o `SelfHealing::Agent` indexa todos os arquivos dos diretórios configurados em `RAG_KNOWLEDGE_BASE_DIR` (pode ser um ou mais, separados por vírgula ou ponto-e-vírgula).
2. Cada arquivo vira um documento vetorizado no `rag_store/`.
3. Antes de cada instrução, o agente recupera os documentos mais relevantes.
4. O conteúdo recuperado é injetado no prompt da LLM.

## Processo de execução do RAG

```
┌─────────────────────────────────────────────────────────────────────────┐
│ 1. INICIALIZAÇÃO                                                        │
│    - env.rb carrega `rag.rb` quando `RAG_ENABLED=true`                  │
│    - `RAG_KNOWLEDGE_BASE_DIR` aponta para `features/pages`              │
│      (Page Objects reais) e `features/support/self_healing/knowledge_base`│
└─────────────────────────────────┬───────────────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 2. INDEXAÇÃO                                                            │
│    - `KnowledgeBase` escaneia recursivamente os diretórios configurados │
│    - Arquivos `.md`, `.txt`, `.yml`, `.yaml`, `.rb` e `.feature` são    │
│      lidos                                                              │
│    - Cada arquivo vira um `Document` (id, texto, metadados)             │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 3. EMBEDDING                                                            │
│    - Cada documento é transformado em vetor                             │
│    - Embedder local por palavras-chave (padrão) ou modelo de API        │
│    - Vetores são normalizados e salvos em `rag_store/`                  │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 4. RECUPERAÇÃO (a cada instrução do agente)                             │
│    - A instrução em linguagem natural também é convertida em vetor      │
│    - `Retriever` busca os `RAG_TOP_K` documentos mais similares         │
│    - Apenas documentos acima de `RAG_MIN_SIMILARITY` são considerados   │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 5. INJEÇÃO DE CONTEXTO                                                  │
│    - Documentos recuperados são formatados e inseridos no prompt        │
│    - A LLM usa esse contexto para gerar/corrigir planos e seletores    │
└─────────────────────────────────────────────────────────────────────────┘
```

## Padrões de projeto aplicados

A camada de RAG foi projetada seguindo princípios que facilitam testes, manutenção e extensão:

| Padrão | Onde está | Benefício |
|--------|-----------|-----------|
| **Repository** | `Rag::Store` | Abstrai a persistência do índice vetorial (JSON local). |
| **Factory** | `Rag::Embedder.default` | Escolhe entre embedder local ou remoto sem expor lógica ao consumidor. |
| **Adapter** | `Rag::ApiEmbedder` | Isola a API de embeddings (formato OpenAI) do restante do código. |
| **Strategy** | `KeywordEmbedder` vs `ApiEmbedder` | Troca de estratégia de embedding via configuração, sem mudar `KnowledgeBase`. |
| **Value Object** | `Rag::Document` | Representa um documento indexado de forma imutável. |
| **Dependency Injection** | `KnowledgeBase` recebe `store` e `embedder` | Permite testes com doubles e troca fácil de implementações. |

## Organização sugerida

```
knowledge_base/
├── business_rules/      # regras de negócio da aplicação
├── flows/               # descrição de fluxos (ex: checkout, cadastro)
├── config/              # configurações específicas de domínio
└── README.md
```

### `business_rules/`

Use para ensinar **o quê** o agente deve testar:

- Regras de negócio da aplicação;
- Validações de campos;
- Mensagens de erro esperadas;
- Dados de teste válidos.

### `flows/`

Use para descrever **como** navegar entre telas:

- Fluxos de checkout, cadastro, login etc.;
- Ordem esperada de telas;
- Decisões condicionais (ex: se o carrinho estiver vazio, mostrar mensagem X).

### `config/`

Use para configurações específicas de domínio:

- Ambientes e URLs;
- Usuários de teste;
- Valores padrão.

## Exemplo

```markdown
# Cadastro de Cliente

Regras:
- O CPF é obrigatório e deve ser válido.
- Após salvar, um modal de confirmação é exibido.
- O botão "Salvar" fica desabilitado enquanto houver erros de validação.
```

## Ativação

No `cucumber.yml` o perfil `rag` está configurado para usar **ambos** os diretórios:

```yaml
rag: RAG_ENABLED=true RAG_TOP_K=3 RAG_MIN_SIMILARITY=0.0 RAG_KNOWLEDGE_BASE_DIR=features/pages,features/support/self_healing/knowledge_base
```

Dessa forma, o RAG recupera tanto os Page Objects reais quanto as regras de negócio, fluxos e validações mantidos em `knowledge_base/`.

Defina também no `.env`:

```bash
AI_API_KEY=sua-chave-aqui
BASE_URL=https://api.moonshot.ai/v1
```

Execute com o perfil `rag`:

```bash
bundle exec cucumber -p self_healing -p rag features/specs/self_healing/login_self_healing.feature
```

Ou use o perfil `auto_correction`, que também ativa o RAG e corrige os Page Objects automaticamente quando um `ElementNotFound` é detectado durante a execução dos steps:

```bash
bundle exec cucumber -p auto_correction features/specs/login.feature
```

## Configuração de embedding

Opcionalmente, configure um modelo de embedding. Exemplo com OpenAI:

```bash
RAG_EMBEDDING_MODEL=text-embedding-3-small
RAG_EMBEDDING_API_KEY=sua_chave
RAG_EMBEDDING_BASE_URL=https://api.openai.com/v1
```

Exemplo com **Jina AI `jina-embeddings-v3`**:

```bash
RAG_EMBEDDING_MODEL=jina-embeddings-v3
RAG_EMBEDDING_API_KEY=sua_chave_jina
RAG_EMBEDDING_BASE_URL=https://api.jina.ai/v1
RAG_EMBEDDING_DIMENSIONS=1024
RAG_EMBEDDING_TASK=retrieval.passage
RAG_EMBEDDING_TASK_QUERY=retrieval.query
```

> **Atenção:** ao trocar de modelo ou dimensões, o `rag_store/` é reindexado automaticamente na próxima execução.

Se não configurar um modelo de embedding, o sistema usa um embedder local baseado em palavras-chave (sem custo de API, mas menos preciso).

## Boas práticas

1. **Mantenha os documentos focados**: um documento por tema facilita a recuperação direcionada.
2. **Use termos consistentes**: se o Page Object chama um campo de `in_user_id`, use o mesmo nome nos documentos de regra de negócio.
3. **Evite duplicar Page Objects**: deixe os arquivos `.rb` em `features/pages/` e use `knowledge_base/` apenas para regras, fluxos e configurações.
4. **Controle o tamanho**: documentos muito grandes podem diluir a relevância. Divida em arquivos menores quando necessário.
5. **Versione junto com o código**: a base de conhecimento evolui com a aplicação; mantenha-a no repositório.

## Troubleshooting

| Sintoma | Causa provável | Solução |
|---------|----------------|---------|
| RAG não retorna documentos | `RAG_MIN_SIMILARITY` muito alto | Diminua o valor (ex: `0.0`) para testes. |
| Índice desatualizado | Arquivos foram alterados após a indexação | Apague `features/support/self_healing/rag_store/` ou use outro modelo/dimensão para forçar reindexação. |
| Erro de API de embedding | `RAG_EMBEDDING_API_KEY` inválida ou API fora do ar | Verifique a chave e a URL base; o sistema faz fallback para embedder local. |
| Documentos `.rb` não aparecem | Arquivo está dentro de `knowledge_base/` em vez de `features/pages/` | Mova Page Objects para `features/pages/` e deixe apenas documentos de conhecimento em `knowledge_base/`. |
