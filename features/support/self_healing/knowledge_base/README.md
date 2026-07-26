# Knowledge Base — RAG do SelfHealing

Coloque aqui documentos que ajudem o agente a tomar decisões melhores.

## Tipos de documentos suportados

- `.md` — documentação de funcionalidades, regras de negócio, fluxos
- `.txt` — anotações textuais
- `.yml` / `.yaml` — configurações específicas de domínio
- `.rb` — Page Objects de referência (para manter consistência na geração)
- `.feature` — cenários Gherkin de referência

## Como funciona

1. Ao iniciar, o `SelfHealing::Agent` indexa todos os arquivos desta pasta.
2. Cada arquivo vira um documento vetorizado no `rag_store/`.
3. Antes de cada instrução, o agente recupera os documentos mais relevantes.
4. O conteúdo recuperado é injetado no prompt da LLM.

## Organização sugerida

```
knowledge_base/
├── business_rules/      # regras de negócio da aplicação
├── page_objects/        # Page Objects de referência
├── flows/               # descrição de fluxos (ex: checkout, cadastro)
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
RAG_ENABLED=true
```

Opcionalmente, configure um modelo de embedding:

```bash
RAG_EMBEDDING_MODEL=text-embedding-3-small
RAG_EMBEDDING_API_KEY=sua_chave
RAG_EMBEDDING_BASE_URL=https://api.openai.com/v1
```

Se não configurar um modelo de embedding, o sistema usa um embedder local baseado em palavras-chave (sem custo de API, mas menos preciso).
