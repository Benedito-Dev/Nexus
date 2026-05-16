# Nexus — Roadmap

> Roadmap em fases com marcos concretos. Cada fase tem um critério de "pronto" claro. O objetivo é evitar deriva durante a maratona de desenvolvimento.

> **Princípio:** uma fase só termina quando o critério está objetivamente atendido. Sem "quase pronto". Sem pular fase.

---

## Visão geral das fases

| Fase | Nome | Critério de pronto |
|---|---|---|
| **0** | Fundação | Escritório vazio renderiza, WebSocket conecta, protocolo de eventos definido |
| **1** | Agentes fake animados | Diretor + 2 agentes scriptados executam uma tarefa pré-programada de ponta a ponta visualmente |
| **2** | Primeiro agente real | Diretor real (Claude/Groq) interpreta tarefa do usuário e dispara fluxo scriptado nos demais |
| **3** | Time completo real | Todos os agentes do MVP são LLMs reais com personalidade configurável |
| **4** | Persistência e projetos | Projetos isolados, memória entre sessões, pré-carregamento de contexto |
| **5** | Integrações reais | Notion + GitHub funcionais via MCP |
| **6** | Pronto para usuários | BYOK, auth, billing básico, deploy |

---

## Fase 0 — Fundação

**Objetivo:** ter a infraestrutura básica funcionando. Nada visualmente impressionante ainda.

**Entregas:**

- Repositório inicializado com estrutura de pastas definida (frontend/, backend/, docs/)
- Frontend React + Vite com Canvas vazio renderizando um background simples
- Backend FastAPI rodando com endpoint WebSocket funcional
- Comunicação WebSocket frontend ↔ backend testada com mensagem ping/pong
- **Protocolo de eventos definido em documento separado** (schema JSON de cada tipo de evento: `agent.move`, `agent.thinking`, `agent.speak`, `agent.status`, `task.start`, `task.complete`, etc.)
- Tailwind configurado
- Linter e formatter configurados em ambos os lados

**Critério de pronto:**
- `npm run dev` no frontend abre uma página com Canvas vazio
- `uvicorn main:app` no backend sobe sem erro
- Frontend conecta no WebSocket e troca uma mensagem com o backend
- O documento `eventos.md` (ou similar) está escrito com o schema completo de eventos

**Por que essa fase importa:** sem protocolo de eventos definido, a Fase 1 vai produzir código que precisará ser refeito quando entrarem agentes reais.

---

## Fase 1 — Agentes fake animados (a "demo do uau")

**Objetivo:** ter a parte visual demonstrável com agentes scriptados. É a primeira versão "mostrável".

**Entregas:**

- Sprite/representação visual definida para personagens (decisão tomada: pixel art prontos? gerados? mão?)
- Pelo menos 3 agentes visíveis no escritório com mesas próprias (Diretor + 2 outros)
- Animações básicas: idle, andar, pensando, digitando
- Speech bubbles funcionais (pílulas curtas sobre a cabeça)
- Movimento dos agentes pelo escritório (ir até a mesa de outro, ir até uma sala)
- Chat lateral fixo renderizando mensagens
- **Script demo:** o usuário digita uma tarefa, e o Diretor (scriptado) "delega" pros outros agentes scriptados, que fingem trabalhar e produzem um resultado pré-programado
- Tudo usando o protocolo de eventos da Fase 0 — frontend não sabe que é fake

**Critério de pronto:**
- Você consegue gravar um vídeo de 60s do Nexus executando uma tarefa scriptada
- O vídeo é convincente o suficiente pra você mostrar pra alguém e a pessoa entender o conceito
- Nenhuma parte do código frontend precisa mudar quando agentes reais entrarem (só o "cérebro" no backend)

**Por que essa fase importa:** valida o conceito visual e a arquitetura do protocolo. Se nesta fase você descobrir que "agentes andando pelo escritório" não fica bom em pixel art, é hora de descobrir, não depois.

---

## Fase 2 — Primeiro agente real (Diretor)

**Objetivo:** trocar o cérebro do Diretor de scriptado pra LLM real, mantendo os demais agentes scriptados.

**Entregas:**

- Camada de provider de LLM no backend (abstração sobre Anthropic / Groq / OpenAI)
- Configuração de chave de API via variável de ambiente (BYOK virá na Fase 6)
- System prompt do Diretor definido e versionado
- Diretor recebe tarefa do usuário em linguagem natural, decompõe em subtarefas, e dispara os scripts dos agentes fake na ordem certa
- Streaming token-a-token da resposta do Diretor no chat lateral
- Histórico da conversa do Diretor mantido na sessão (em memória, sem persistência ainda)

**Critério de pronto:**
- Você digita tarefas livres em linguagem natural e o Diretor as decompõe de forma plausível
- Os agentes fake são acionados na ordem certa de acordo com a decomposição
- Visualmente, é indistinguível da Fase 1 — a "casa" não mudou, só o "cérebro" do Diretor

---

## Fase 3 — Time completo real

**Objetivo:** todos os agentes do MVP rodam com LLM real.

**Entregas:**

- System prompts versionados para os 7 agentes (Diretor, Estrategista, Documenter, Arquiteto, Implementer, Reviewer, Designer)
- Toggle de modo profissional vs com personalidade nas configurações
- Mecanismo de comunicação entre agentes (Diretor passa contexto para Implementer, que passa para Reviewer, etc.)
- Tratamento de erro: se um agente falha ou demora, o Diretor decide o que fazer
- Estimativa de tokens antes de executar (cálculo grosseiro, mostrado pro usuário)
- Cap configurável de tokens por tarefa

**Critério de pronto:**
- O caso de uso âncora roda de ponta a ponta com **mocks** das integrações (Notion e GitHub ainda fakes)
- O usuário consegue interromper via chat e os agentes obedecem
- Custos estão visíveis e controlados

---

## Fase 4 — Persistência e projetos

**Objetivo:** transformar o Nexus de "sessão única" em ferramenta de uso contínuo.

**Entregas:**

- Banco de dados configurado (provável: PostgreSQL; SQLite em dev)
- Conceito de "Projeto" implementado com workspace isolada
- Criação, listagem, edição e exclusão de projetos via UI
- Pré-carregamento de contexto: upload de `.md` ou apontamento pra workspace do Notion (ainda mockada nesta fase)
- Resumo de sessão gerado ao fim de cada execução e persistido
- Histórico do projeto disponível como contexto na próxima sessão

**Critério de pronto:**
- Você fecha o Nexus, abre amanhã, escolhe um projeto, e os agentes "lembram" do que aconteceu ontem (via resumo)
- Dois projetos diferentes não vazam contexto entre si

---

## Fase 5 — Integrações reais

**Objetivo:** plugar Notion e GitHub de verdade.

**Entregas:**

- Integração Notion via MCP: autenticação, listagem de páginas, leitura de conteúdo, busca
- Integração GitHub via MCP: criar repo, fazer commit, criar PR
- Sala visual do Notion no escritório (agente "anda" até lá quando vai buscar info)
- Sala visual do GitHub idem
- Tratamento de erros de API (token inválido, rate limit, página não encontrada)

**Critério de pronto:**
- O caso de uso âncora roda de ponta a ponta com integrações **reais**
- Você consegue executar a tarefa "busca no meu Notion, enriquece com web, gera código, sobe no GitHub" sem mocks

---

## Fase 6 — Pronto para usuários

**Objetivo:** Nexus deixa de ser projeto pessoal e vira produto utilizável por terceiros.

**Entregas:**

- Autenticação: email/senha + Google OAuth
- BYOK: usuário cadastra suas próprias chaves de API (Anthropic, Groq, OpenAI) com criptografia em repouso
- Billing básico (se o modelo de cobrança já estiver definido nesta altura) — pode ser Stripe simples
- Deploy: frontend (Vercel ou similar), backend (Railway, Fly.io, ou VPS própria), banco de dados gerenciado
- Página de landing simples explicando o produto
- Onboarding mínimo: usuário cria conta, conecta chave, cria primeiro projeto

**Critério de pronto:**
- Uma pessoa que não é você consegue criar conta, conectar a chave, criar um projeto e executar uma tarefa sem precisar de tutorial 1:1
- O sistema sustenta 5-10 usuários simultâneos sem cair

---

## Fora do roadmap (parking lot)

Itens válidos mas explicitamente fora do caminho crítico. Podem entrar depois da Fase 6 conforme demanda real.

- Agentes customizados criados pelo usuário
- Mais integrações (Google Drive, Linear, Figma, Slack)
- Tier "managed" (sem BYOK)
- Marketplace de agentes
- Mobile / responsivo
- Multiplayer / colaboração
- Customização visual do escritório
- Voz / TTS

---

## Princípios para executar o roadmap

1. **Não pule fases.** Cada fase prepara a próxima. Pular significa retrabalho.
2. **Critério de pronto é objetivo, não sentimento.** Se o critério não está atendido, a fase não acabou.
3. **Revise este roadmap a cada fase concluída.** Aprendizados de uma fase podem mudar a próxima — atualize aqui antes de seguir.
4. **Sem prazos rígidos.** Filosofia é maratona. Mas anote quando cada fase começou e terminou — ajuda a calibrar expectativa pras próximas.
5. **Se uma fase passar de 1 mês, pare e investigue.** Pode ser que o escopo dela esteja errado.

---

## Histórico de fases

Registrar aqui quando cada fase começa e termina.

- **Fase 0** — Não iniciada
- **Fase 1** — Não iniciada
- **Fase 2** — Não iniciada
- **Fase 3** — Não iniciada
- **Fase 4** — Não iniciada
- **Fase 5** — Não iniciada
- **Fase 6** — Não iniciada