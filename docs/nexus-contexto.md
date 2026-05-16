# Nexus — Documento de Contexto do Projeto

> Cole este documento no início de qualquer nova conversa com Claude para restaurar o contexto completo do projeto Nexus. Documento único e versionado — toda alteração de visão ou decisão deve refletir aqui.

---

## 1. O que é o Nexus

Nexus é uma plataforma visual de orquestração de múltiplos agentes IA, com interface imersiva de escritório 2D em pixel art (estética "Stardew Valley mais dark").

O usuário dá uma tarefa de alto nível. Em vez de receber apenas uma resposta, ele **assiste** uma equipe de agentes IA trabalhando: cada um na sua mesa, comunicando-se entre si, indo a salas especiais buscar informação, reunindo-se para alinhar, e entregando o resultado final.

A experiência é de ser um **diretor observando sua equipe trabalhar** — não de alguém digitando prompts.

### Caso de uso âncora

Todas as decisões técnicas e de produto devem ser medidas contra este fluxo:

> "Nexus, busca no meu Notion toda a documentação sobre o projeto X, enriquece com fontes da internet, passa pro Implementer escrever um código base mockado seguindo o Design System do agente Designer, e sobe num repositório GitHub."

Se uma decisão atrapalha esse fluxo, ela está errada. Se uma feature não aparece nesse fluxo (ou em variações próximas dele), ela não é MVP.

---

## 2. Visão e propósito

**Para quem é:** três públicos simultâneos, em ordem de prioridade durante o desenvolvimento:

1. **Uso pessoal** — o criador como primeiro usuário real. Garante que o produto resolve dor concreta.
2. **Produto comercial** — venda de acesso. Modelo de negócio em aberto, mas BYOK (bring your own key) é o caminho técnico definido.
3. **Portfólio** — caso a comercialização não decole, o Nexus permanece como peça de portfólio robusta e demonstrável.

A filosofia subjacente: **mesmo no pior cenário comercial, o projeto vale a pena.** Isso libera o desenvolvimento de pressão por validação precoce e permite executar com calma.

**O que empolga igualmente:** a imersão visual e a orquestração técnica. Nenhum dos dois é "meio" para o outro — ambos são o produto.

---

## 3. Arquitetura conceitual

### 3.1 As três camadas

**Camada 1 — Escritório Visual (Frontend)**

- Ambiente 2D top-down em pixel art, renderizado em React + Canvas
- Câmera onisciente (sem avatar do usuário)
- Cada agente é um personagem visível na sua mesa
- Salas: mesas individuais dos agentes, sala de reunião, salas de integração (Notion, GitHub, etc.)
- Speech bubbles curtos sobre a cabeça dos personagens = status real do agente
- Stream token-a-token da resposta final = aparece no chat lateral, não no bubble
- Comunicação em tempo real com backend via WebSocket (Socket.io)

**Camada 2 — Orquestrador (Backend)**

- Node.js + TypeScript + Fastify + Socket.io
- Agente Diretor recebe a tarefa, quebra em subtarefas e distribui
- Agentes se comunicam por mensagens internas (protocolo de eventos único)
- Cada agente tem papel fixo e system prompt configurável (incluindo personalidade opcional)
- Eventos de estado emitidos em tempo real pro frontend (movendo, pensando, escrevendo, reunindo)

**Camada 3 — Salas Especiais (Integrações)**

- Não são agentes — são ferramentas/ambientes
- Um agente "entra" na sala, executa uma ação (ex.: buscar página no Notion), "volta" com o conteúdo
- Implementadas como MCPs ou APIs REST diretas
- MVP foca em mock; integrações reais entram em fases posteriores (ver roadmap)

### 3.2 Princípio arquitetural crítico

**Os agentes fake do MVP devem usar exatamente o mesmo protocolo de eventos dos agentes reais.**

Razão: a transição de "agentes scriptados" para "agentes reais com LLM" deve ser apenas trocar o cérebro, sem refazer a casa. O frontend não pode saber se está conversando com um script ou com Claude/Groq.

Implicação prática: define o **schema dos eventos WebSocket** antes de implementar qualquer agente, fake ou real. Esse schema vive no pacote compartilhado do monorepo (`shared/`), garantindo tipagem unificada entre frontend e backend em compile time.

---

## 4. Os agentes

### 4.1 Time inicial (MVP e V1)

| Agente | Papel | Pré-carregamento |
|---|---|---|
| **Diretor** | Recebe tarefa do usuário, quebra em subtarefas, distribui, sintetiza resultado final | Genérico |
| **Estrategista** | Planeja, pesquisa, debate ideias, faz análises meticulosas | Contexto do projeto |
| **Documenter** | Pesquisa documental ampla — Notion, PDFs, web, arquivos. Debate de ideias | Genérico |
| **Arquiteto** | Planeja projetos de código (estrutura, stack, decisões técnicas) | Contexto do projeto |
| **Implementer** | Escreve código | Contexto do projeto |
| **Reviewer** | Valida código e lógica de negócio, critica resultados | Genérico |
| **Designer** | Especialista em design system | Pode receber DS de referência |

**Ponto de atenção registrado:** Estrategista e Arquiteto têm sobreposição funcional. Não resolver agora; observar no uso real e, se necessário, fundir em um agente com dois modos.

### 4.2 Identidade dos agentes

- **Nomes próprios + papéis.** Ex.: "Marina, Diretora"; "Lúcia, Pesquisadora".
- **Toggle de personalidade** nas configurações:
  - *Modo profissional* — agente neutro, objetivo, sem maneirismos. Padrão para uso empresarial.
  - *Modo com personalidade* — agente com jeito próprio, manias, opiniões. Padrão para uso pessoal.
- Tecnicamente, é a mesma engine — só troca o system prompt. Isso já deve estar arquitetado desde o início.

### 4.3 Agentes customizados (fase futura)

O usuário poderá criar seus próprios agentes (definir nome, papel, system prompt, ferramentas que pode usar). Não é MVP, mas a arquitetura de agentes deve ser feita pensando nessa extensibilidade desde o começo.

---

## 5. Interação do usuário com o Nexus

### 5.1 Interface de comunicação

**Chat lateral fixo é a interface principal.** É onde 95% das interações acontecem: dar tarefa, receber atualizações, interromper, dar correções.

**Clicar em um agente** abre um popover leve com:
- O que ele está fazendo agora ("Pesquisando no Notion: documentação do projeto X")
- Botão "Falar com ele" — que **foca o input do chat lateral e adiciona `@NomeDoAgente`** no início

Decisão: uma única mecânica de chat, dois jeitos de invocar. Sem janelas paralelas, sem chat por agente, sem refatoração futura.

### 5.2 Interrupção e correção

O usuário pode interromper a qualquer momento — ele é o diretor. Quando vê uma regra de negócio sendo violada ou quer redirecionar:

- Escreve no chat (geral ou com `@AgenteEspecífico`)
- O Diretor recebe, decide se redistribui ou se a correção vai direto pro agente mencionado
- Execução pode continuar, pausar ou ser cancelada conforme a instrução

### 5.3 Câmera e ponto de vista

Câmera onisciente, sem avatar do usuário no escritório. O usuário é o observador acima de tudo, não um personagem dentro do mundo.

---

## 6. Persistência, projetos e memória

### 6.1 Projetos como conceito de primeira classe

Cada projeto tem:
- Workspace isolada
- Repositório associado (opcional)
- Documentação própria (Notion workspace ou pasta de arquivos `.md`)
- Histórico próprio
- Agentes pré-carregados com contexto do projeto (Estrategista, Arquiteto, Implementer)
- Eventualmente, agentes customizados específicos do projeto

Projetos são separados e independentes. "Site da empresa X" não vaza contexto pra "Pesquisa pessoal sobre Y".

No Socket.io, cada projeto é uma **room** — isso isola naturalmente o fluxo de eventos entre projetos do mesmo usuário.

### 6.2 Pré-carregamento de contexto

O usuário aponta a fonte de verdade do projeto, de duas formas:

1. **Workspace do Notion** — Nexus indexa as páginas e disponibiliza pros agentes
2. **Arquivo `.md` carregado** — usuário sobe um documento de contexto manualmente

Outras fontes (GitHub repos, Google Drive, etc.) entram em fases posteriores.

### 6.3 Memória entre sessões

**Não persistir histórico completo de cada agente individualmente** — pesa demais, ainda mais com 8-10 agentes.

**Persistir um resumo enxuto consolidado** por projeto:
```
Sessão de 16/05/2026
- Estrategista: definiu arquitetura X, levantou riscos Y e Z
- Implementer: criou módulo de autenticação, pendente revisão
- Reviewer: aprovou módulo de pagamentos com 2 ressalvas
```

O resumo é gerado ao final de cada sessão (pelo próprio Diretor ou por um job de pós-processamento) e fica disponível como contexto na próxima sessão.

---

## 7. Modelo de negócio

### 7.1 Decisões tomadas

- **BYOK (Bring Your Own Key)** — usuário traz a própria chave de API (Anthropic, Groq, OpenAI, etc.). Nexus não revende tokens no MVP.
- **Escritório isolado por usuário** — sem multiplayer no MVP ou V1.

### 7.2 Em aberto

- Modelo de cobrança: assinatura mensal, pay-per-use, créditos, freemium — a definir conforme validação.
- Tier "managed" futuro: oferecer infra completa (sem BYOK) como upgrade, depois do MVP estabilizado.

### 7.3 Controle de custo do usuário

- **Estimativa antes de executar:** "essa tarefa vai usar ~3 agentes, estimativa de 15-40k tokens, ~R$0,80 com Claude Sonnet". Cálculo grosseiro, mas o número visível muda comportamento.
- **Cap configurável:** usuário define limite de tokens por tarefa nas configurações.
- **Aviso ao ultrapassar:** se passar do cap em meio à execução, pausa e pede confirmação.

---

## 8. Stack técnica

### 8.1 Frontend

- **React + Vite** — base do app
- **TypeScript estrito** — tipagem forte, sem `any` solto
- **Canvas API** para renderização do escritório (sprites, animações, movimento dos agentes)
- **Tailwind CSS** para chrome (chat lateral, configurações, modais)
- **Socket.io client** para comunicação em tempo real com backend

### 8.2 Backend

- **Node.js + TypeScript** estrito
- **Fastify** como framework HTTP (mais performático e moderno que Express, com schema validation nativa)
- **Socket.io** para WebSocket (rooms = projetos, reconexão automática, broadcasting)
- **Zod** para validação de schemas de eventos e payloads
- **Prisma** como ORM (chega na Fase 4)
- **LLMs suportados via BYOK:** Anthropic (Claude), Groq (Llama), OpenAI — abstrair via camada de provider
- **Integrações via MCP** (preferência, ecossistema TS é first-class) ou REST direto

### 8.3 Estrutura do repositório (monorepo flat)

```
nexus/
├── backend/             # Fastify + Socket.io + TS
├── frontend/            # React + Vite + TS
├── shared/              # Schemas Zod, tipos de eventos, constantes
├── docs/                # Documentação (este arquivo, roadmap, eventos)
├── CLAUDE.md            # Instruções pro Claude (opcional)
├── README.md
├── LICENSE
├── pnpm-workspace.yaml  # Lista: backend, frontend, shared
└── package.json         # Raiz do workspace
```

**Razão do monorepo:** o protocolo de eventos é o coração arquitetural do Nexus. Frontend e backend precisam concordar sobre o schema de cada evento. Definindo os schemas Zod em `shared`, ambos os lados importam o mesmo código (`import { AgentMoveSchema } from '@nexus/shared'`) e qualquer divergência vira erro de compilação — não bug em produção.

**Por que flat (sem `apps/` e `packages/`):** os nomes `apps/` e `packages/` são convenção do Turborepo/Nx, não obrigatoriedade do pnpm. Pra um workspace com 3 pastas (backend, frontend, shared), o aninhamento extra atrapalha mais do que ajuda — pior navegação no editor, paths mais longos, e nenhum ganho real. pnpm workspace funciona perfeitamente com a estrutura flat: basta listar `backend`, `frontend` e `shared` no `pnpm-workspace.yaml`. Se um dia o projeto crescer pra ter múltiplos apps (mobile, CLI) ou múltiplos packages compartilhados (ui-kit, agents-sdk), aí sim faz sentido reorganizar em `apps/` e `packages/`.

### 8.4 Ferramentas

- **pnpm** como gerenciador de pacotes (mais rápido, melhor pra monorepo que npm/yarn)
- **Biome** ou **ESLint + Prettier** pra linting e formatting (decisão a tomar na Fase 0)
- **Vitest** pra testes
- **Docker** pra dev local do banco (a partir da Fase 4)

### 8.5 Em aberto

- LLM padrão recomendado pro MVP (provável: Claude Sonnet pelo equilíbrio qualidade/custo)
- Banco de dados (provável: PostgreSQL pra produção, SQLite pra dev — Prisma suporta os dois)
- Representação visual dos personagens: sprites pixel art prontos vs gerados vs criados à mão — a decidir

---

## 9. Princípios de design

### 9.1 Estética visual

- **Pixel art 2D top-down**, inspiração base: imagem de referência estilo Gather.town / virtual office
- **"Stardew Valley mais dark"** — manter o charme cozy do pixel art, ajustando paleta e ambiência
- **Não é cyberpunk puro** — evitar clichê neon saturado. O dark vem da paleta sóbria, não de efeitos
- Densidade visual média: detalhes ambientais (plantas, monitores, café) sem poluir

### 9.2 Princípios de produto

1. **A imersão é parte do produto, não decoração.** Se o visual não comunica o que tá acontecendo, ele falhou.
2. **O usuário é diretor, não digitador.** Toda decisão de UX deve reforçar a sensação de observação e comando, não de prompt engineering.
3. **Status real > teatro.** Speech bubbles refletem o que o agente está realmente fazendo. Não inventar atividade falsa pra parecer vivo.
4. **Mesma engine, dois figurinos.** Personalidade vs profissional, agente fake vs real — tudo deve ser configuração, nunca código duplicado.
5. **Projeto é unidade de contexto.** Nada vaza entre projetos sem ação explícita do usuário.
6. **Tipos compartilhados são contrato.** O `shared/` é a fonte da verdade do protocolo de eventos. Frontend e backend não inventam tipos por conta própria.

---

## 10. O que o Nexus NÃO é (escopo negativo)

Decisões explícitas sobre o que **não** está no caminho crítico. Não é desistência — é foco. Cada item pode entrar depois.

- **Mobile.** Pixel art top-down com 6+ agentes não cabe em tela de celular. Desktop-first.
- **Multiplayer / colaboração.** Cada usuário tem seu escritório isolado. Sem salas compartilhadas, sem ver agentes de outros usuários.
- **Marketplace de agentes de terceiros.** Usuário cria pra si mesmo (fase futura). Marketplace é projeto separado.
- **SSO / SAML / OAuth empresarial.** Email/senha + Google OAuth no MVP.
- **Editor de código embutido.** Implementer escreve, mostra diff, salva no repo. Edição acontece no editor do usuário.
- **Voz / TTS / áudio.** Charmoso mas rabbit hole grande e fora do caso de uso âncora.
- **Customização visual do escritório pelo usuário.** Mesmo escritório pra todo projeto no MVP.
- **Versionamento / "rewind" de conversas.** Complexo e ninguém pediu.
- **Frameworks de orquestração multi-agente prontos.** LangChain.js, Mastra, CrewAI, AutoGen abstraem demais e escondem o protocolo. Pro Nexus, orquestração é escrita à mão — controle total, zero magia escondida.

---

## 11. Riscos conhecidos

- **Latência de LLM matando imersão.** 3-30s por resposta. Mitigação: status streaming via WebSocket + animações de pensando + resposta token-a-token no chat.
- **Custo de API rodando 4-6 agentes por tarefa.** Mitigação: BYOK + estimativa pré-execução + cap configurável.
- **Complexidade do orquestrador.** Coordenar 6 agentes com dependências entre tarefas pode virar pesadelo. Mitigação: começar com workflow linear simples (Diretor → 1 agente → resultado) e evoluir.
- **Frontend Canvas pesado.** Animações de pixel art com muitos agentes pode degradar performance. Mitigação: budget de performance desde o início (60fps com 8 agentes ativos).
- **Visual perfeito e produto vazio.** Risco de gastar meses no escritório bonito e descobrir que o orquestrador não escala. Mitigação: protocolo de eventos definido antes de qualquer implementação, e fakes que respeitam esse protocolo.
- **Estrategista vs Arquiteto sobrepostos.** Risco do usuário não saber pra qual mandar tarefa. Observar no uso real.
- **Desincronização frontend/backend do protocolo de eventos.** Risco real em qualquer projeto com schema compartilhado. Mitigação: monorepo + `shared/` + TypeScript estrito — divergência vira erro de compilação.

---

## 12. Glossário

- **Agente** — Personagem visível no escritório com papel definido, system prompt e capacidade de executar ações. No MVP, é um script; depois, um LLM com ferramentas.
- **Diretor** — Agente especial que recebe a tarefa do usuário, decompõe e distribui aos demais. Também sintetiza o resultado final.
- **Sala** — Espaço visual no escritório. Pode ser uma mesa de agente, sala de reunião, ou **sala de integração** (Notion, GitHub) — esta última é uma ferramenta visualmente representada.
- **Room (Socket.io)** — Conceito técnico do Socket.io: canal lógico de eventos. No Nexus, cada projeto vira uma room — isolando o tráfego de eventos por contexto.
- **Projeto** — Unidade de contexto isolada. Tem workspace, documentação, histórico e agentes pré-carregados próprios.
- **Workspace** — Espaço lógico de um projeto: arquivos, configurações, integrações conectadas.
- **Pré-carregamento** — Contexto injetado no system prompt de um agente no início da sessão (ex.: documentação do projeto, design system).
- **BYOK** — *Bring Your Own Key.* Usuário fornece a própria chave de API do provider de LLM.
- **MCP** — *Model Context Protocol.* Protocolo padrão para conectar LLMs a ferramentas/integrações externas.
- **Speech bubble** — Balão de fala curto sobre a cabeça do personagem, indicando status real (não é resposta do agente).
- **Stream token-a-token** — Resposta final do agente aparecendo letra por letra no chat lateral conforme é gerada pela LLM.
- **Modo profissional / Modo com personalidade** — Toggle de system prompt: agentes neutros e objetivos vs agentes com jeito próprio.
- **Caso de uso âncora** — Fluxo Notion → Web → Implementer → GitHub. Critério de teste para toda decisão.
- **Pacote compartilhado (`shared/`)** — Pasta do monorepo que contém os schemas Zod do protocolo de eventos. Importado por frontend e backend (via `@nexus/shared`) para garantir contrato único.

---

## 13. Histórico de decisões

Toda alteração relevante neste documento deve ser registrada aqui com data e motivo.

- **2026-05-16 (inicial)** — Versão inicial do documento de contexto. Decisões consolidadas: nome (Nexus), estética (pixel art top-down, Stardew dark), câmera (onisciente), interação (chat lateral + popover em clique), time de agentes (7 papéis), BYOK, projetos isolados, memória resumida, escopo negativo definido.

- **2026-05-16 (stack backend)** — Stack do backend trocada de Python + FastAPI para **Node.js + TypeScript + Fastify + Socket.io + Zod**. Estrutura migrada para monorepo pnpm com `shared/` para tipos do protocolo de eventos.
  - **Motivo principal:** o coração arquitetural do Nexus é o protocolo de eventos compartilhado entre frontend e backend. Em Node + TS, esse protocolo vive em um pacote único importado pelos dois lados — divergência vira erro de compilação. Em Python + JS, o mesmo schema precisaria ser duplicado e mantido em sincronia manualmente.
  - **Motivos secundários:** Socket.io é objetivamente mais maduro que qualquer solução WebSocket Python (rooms, reconexão, broadcasting nativos); MCP é first-class em TS (servidores prontos da comunidade são majoritariamente Node); uma linguagem só reduz custo cognitivo no projeto solo de maratona; tipagem estática real (vs runtime do Pydantic) ajuda em refactors ao longo de meses.
  - **Trade-offs aceitos:** ecossistema acadêmico de orquestração multi-agente é mais rico em Python (LangChain, CrewAI, AutoGen), mas decisão paralela é não usar esses frameworks de qualquer forma (abstraem demais, escondem o protocolo); SDKs de LLM têm leve vantagem em Python pra features bleeding-edge, mas o gap é de dias/semanas, não meses, e não compensa a sobrecarga de duas linguagens.
  - **Pré-requisito da decisão:** confirmação de que o desenvolvedor tem experiência robusta tanto em Python quanto em Node — eliminando "custo de aprendizado" como fator.

- **2026-05-16 (estrutura do monorepo)** — Estrutura do monorepo definida como **flat** (`backend/`, `frontend/`, `shared/` na raiz) em vez do padrão Turborepo/Nx (`apps/` e `packages/`).
  - **Motivo:** com apenas 3 workspaces, o aninhamento extra de `apps/` e `packages/` atrapalha mais do que ajuda — pior navegação no editor, paths mais longos, e nenhum ganho real. pnpm workspace funciona perfeitamente com estrutura flat.
  - **Trade-off aceito:** se o projeto crescer pra ter múltiplos apps (mobile, CLI) ou múltiplos packages compartilhados (ui-kit, agents-sdk), será necessário reorganizar pra `apps/` e `packages/`. Custo dessa reorganização é baixo (mover pastas e atualizar `pnpm-workspace.yaml`) e só vale a pena quando houver necessidade real.