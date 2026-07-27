# Knowledge Base — RAG do SelfHealing

Coloque aqui documentos que ajudem o agente a tomar decisões melhores.

> **Atenção:** os Page Objects usados como referência pelo RAG são os arquivos reais do projeto em [`features/pages/`](../../../pages/). Não mantenha arquivos `.rb` de Page Objects dentro desta pasta, pois eles podem conflitar com as classes já carregadas pelo `features/support/page_helper.rb`.

## Tipos de documentos suportados

- `.md` — documentação de funcionalidades, regras de negócio, fluxos
- `.txt` — anotações textuais
- `.yml` / `.yaml` — configurações específicas de domínio
- `.feature` — cenários Gherkin de referência

## Como funciona

1. Ao iniciar, o `SelfHealing::Agent` indexa todos os arquivos da pasta configurada em `RAG_KNOWLEDGE_BASE_DIR`.
2. Cada arquivo vira um documento vetorizado no `rag_store/`.
3. Antes de cada instrução, o agente recupera os documentos mais relevantes.
4. O conteúdo recuperado é injetado no prompt da LLM.

No `cucumber.yml` o perfil `rag` está configurado para usar os Page Objects reais do projeto:

```yaml
rag: RAG_ENABLED=true RAG_TOP_K=3 RAG_MIN_SIMILARITY=0.0 RAG_KNOWLEDGE_BASE_DIR=features/pages
```

Use a pasta `knowledge_base/` para complementar com regras de negócio, fluxos e validações que não estão nos Page Objects.

## Organização sugerida

```
knowledge_base/
├── business_rules/      # regras de negócio da aplicação
├── flows/               # descrição de fluxos (ex: checkout, cadastro)
├── config/              # configurações específicas de domínio
└── README.md
```

## Exemplo

```markdown
# Cadastro de Cliente

Regras:
- O CPF é obrigatório e deve ser válido.
- Após salvar, um modal de confirmação é exibido.
- O botão "Salvar" fica desabilitado enquanto houver erros de validação.
```

## Ativação

Defina no `.env`:

```bash
AI_API_KEY=sua-chave-aqui
BASE_URL=https://api.moonshot.ai/v1
```

E execute com o perfil `rag`:

```bash
bundle exec cucumber -p self_healing -p rag features/specs/self_healing/login_self_healing.feature
```

Opcionalmente, configure um modelo de embedding:

```bash
RAG_EMBEDDING_MODEL=text-embedding-3-small
RAG_EMBEDDING_API_KEY=sua_chave
RAG_EMBEDDING_BASE_URL=https://api.openai.com/v1
```

Se não configurar um modelo de embedding, o sistema usa um embedder local baseado em palavras-chave (sem custo de API, mas menos preciso).
