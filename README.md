# 🏢 Nexus

> Você dá uma tarefa. Sua equipe de agentes IA cuida do resto — e você assiste tudo acontecer.

Nexus é uma plataforma visual de orquestração de múltiplos agentes IA com interface imersiva de escritório 2D em pixel art. Em vez de digitar prompts e esperar uma resposta, você **observa uma equipe especializada trabalhar**: cada agente na sua mesa, comunicando entre si, se movendo pelo escritório, e entregando o resultado final.

A experiência é de ser um **diretor observando sua equipe** — não alguém colando texto num chat.

---

## ✨ Conceito

```
Você: "Nexus, busca no meu Notion toda a documentação sobre o projeto X,
       enriquece com fontes da internet, passa pro Implementer escrever
       um código base mockado seguindo o Design System do Designer,
       e sobe num repositório GitHub."

Nexus: [Marina (Diretora) analisa a tarefa e distribui para a equipe]
       [Lúcia (Documenter) caminha até a Sala do Notion e busca as páginas]
       [Arquiteto planeja a estrutura do código]
       [Implementer escreve o código na sua mesa]
       [Reviewer valida e aprova]
       [Implementer faz o commit e abre o PR no GitHub]

Você: assistiu tudo em tempo real, interveio quando quis, recebeu o link do PR.
```

---

## 👥 Os Agentes

| Agente | Papel |
|--------|-------|
| 🎯 **Marina — Diretora** | Recebe a tarefa, decompõe, distribui e sintetiza o resultado |
| 🧠 **Estrategista** | Planeja, pesquisa, debate ideias e faz análises meticulosas |
| 📚 **Lúcia — Documenter** | Pesquisa documental ampla: Notion, PDFs, web, arquivos |
| 🏗️ **Arquiteto** | Planeja projetos de código: estrutura, stack, decisões técnicas |
| 💻 **Implementer** | Escreve o código |
| 🔍 **Reviewer** | Valida código e lógica de negócio, critica resultados |
| 🎨 **Designer** | Especialista em design system e padrões visuais |

Cada agente tem **nome próprio, papel fixo e personalidade configurável** (modo profissional ou com personalidade — mesmo código, system prompt diferente).

---

## 🛠️ Stack

### Frontend
- **React + Vite** — base do app
- **Canvas API** — renderização do escritório 2D (sprites, animações, movimento)
- **Tailwind CSS** — chrome lateral (chat, modais, configurações)
- **Socket.io client** — comunicação em tempo real com o backend
- **TypeScript estrito** — zero `any`

### Backend
- **Node.js + Fastify** — servidor HTTP
- **Socket.io** — WebSocket com rooms por projeto
- **Zod** — validação de schemas de eventos
- **Abstração de LLM provider** — Anthropic (Claude), Groq, OpenAI via BYOK

### Shared
- **Protocolo de eventos tipado** — schemas Zod importados por frontend e backend
- Divergência no protocolo vira erro de compilação, não bug em produção

---

## 📁 Estrutura do Repositório

```
nexus/
├── frontend/            # React + Vite + Canvas API
├── backend/             # Node.js + Fastify + Socket.io
├── shared/              # Protocolo de eventos (schemas Zod + tipos)
├── docs/                # Documentação de produto e arquitetura
│   ├── nexus-contexto.md   # Visão, decisões, glossário — documento mestre
│   └── nexus-roadmap.md    # Fases com critérios objetivos de pronto
├── CLAUDE.md            # Instruções e princípios para o Claude Code
├── pnpm-workspace.yaml  # Configuração do monorepo
└── package.json         # Scripts raiz
```

**Por que monorepo flat?** Com 3 workspaces, o aninhamento `apps/packages/` atrapalha mais do que ajuda. pnpm workspace funciona perfeitamente com a estrutura flat.

**Por que `shared/`?** O protocolo de eventos é o coração arquitetural do Nexus. Frontend e backend importam os mesmos tipos — qualquer divergência vira erro de compilação em vez de bug silencioso.

---

## 🗺️ Roadmap

| Fase | Nome | Descrição |
|------|------|-----------|
| **0** | Fundação | Monorepo, protocolo de eventos definido, WebSocket conectando |
| **1** | Agentes fake | Escritório animado com agentes scriptados executando demo de ponta a ponta |
| **2** | Primeiro agente real | Diretor vira LLM real; demais continuam scriptados |
| **3** | Time completo real | Todos os 7 agentes com LLM, personalidade configurável, token cap |
| **4** | Persistência | Projetos isolados, memória entre sessões, pré-carregamento de contexto |
| **5** | Integrações reais | Notion + GitHub via MCP funcionais |
| **6** | Produto | BYOK, auth, billing, deploy — pronto pra outros usuários |

---

## 🚧 Fora do escopo (por decisão consciente)

Não é desistência — é foco. Pode entrar depois da Fase 6.

- 📱 Mobile / responsivo
- 👥 Multiplayer / colaboração
- 🎙️ Voz / TTS
- 🧩 Marketplace de agentes de terceiros
- 🖥️ Editor de código embutido
- 🎨 Customização visual do escritório
- 🔐 SSO / SAML empresarial

---

## ⚙️ Princípios Arquiteturais

1. **Agentes fake e reais usam o mesmo protocolo.** O frontend nunca sabe qual é qual. Trocar de scriptado para LLM real é só trocar o cérebro, não refazer a casa.
2. **`shared/` é a fonte única de verdade.** Nenhum evento definido fora dele.
3. **Projeto é unidade de contexto isolada.** Nada vaza entre projetos sem ação explícita.
4. **Mesma engine, dois figurinos.** Personalidade vs profissional é configuração, nunca código duplicado.
5. **Status real, não teatro.** Speech bubbles refletem o que o agente está fazendo de verdade.

---

## 🔑 BYOK — Bring Your Own Key

O Nexus não revende tokens. Você conecta suas próprias chaves de API (Anthropic, Groq, OpenAI) e tem controle total sobre custo e provider. Antes de cada tarefa, o Nexus exibe uma estimativa de tokens e custo — e respeita o cap que você configurar.

---

*Desenvolvido como produto pessoal, comercial e portfólio — nessa ordem de prioridade.*
