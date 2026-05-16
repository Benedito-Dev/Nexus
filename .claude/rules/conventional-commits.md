# Conventional Commits — Nexus

Padrão internacional de commits adaptado para o Nexus.

---

## FORMATO OBRIGATÓRIO

```
<type>(<scope>): <subject>

<body>

<footer>
```

---

## 1. TYPE

| Type | Uso | Exemplo Nexus |
|------|-----|---------------|
| `feat` | Nova funcionalidade | `feat(canvas): adiciona animação de agente pensando` |
| `fix` | Correção de bug | `fix(websocket): corrige desconexão após 30s idle` |
| `docs` | Documentação | `docs(shared): documenta eventos de agente v1` |
| `refactor` | Refatoração sem mudança de comportamento | `refactor(agentes): extrai interface Agent para shared/` |
| `perf` | Performance | `perf(canvas): otimiza draw loop para 60fps com 8 agentes` |
| `test` | Testes | `test(backend): cobre cenário de agente fake completando tarefa` |
| `chore` | Build, configs, deps | `chore(deps): atualiza socket.io para 4.8` |
| `style` | Formatação | `style: aplica biome em todo src/` |
| `ci` | CI/CD | `ci: adiciona workflow de typecheck nos três workspaces` |

---

## 2. SCOPE — Módulos do Nexus

| Scope | Quando usar |
|-------|-------------|
| `frontend` | Mudança genérica no workspace frontend/ |
| `backend` | Mudança genérica no workspace backend/ |
| `shared` | Mudança no protocolo de eventos ou tipos compartilhados |
| `canvas` | Renderização Canvas 2D, game loop, sprites |
| `agentes` | Implementação de agentes (fake ou reais), system prompts |
| `websocket` | Socket.io — handlers, eventos, rooms |
| `llm` | LLM providers, abstração, streaming |
| `orquestrador` | Diretor, decomposição de tarefas, distribuição |
| `projetos` | Conceito de projeto, isolamento, workspace |
| `auth` | Autenticação, BYOK (Fase 6) |
| `notion` | Integração Notion MCP (Fase 5) |
| `github` | Integração GitHub MCP (Fase 5) |
| `docs` | Documentação (README, CLAUDE.md, docs/) |
| `config` | Configuração de projeto (tsconfig, vite.config, etc.) |

---

## 3. SUBJECT

- **Português**, imperativo, max 72 chars
- Primeira letra minúscula, sem ponto final
- Claro e específico

```
CORRETO:  feat(canvas): renderiza speech bubble sobre agente ativo
CORRETO:  feat(shared): adiciona evento agent.error ao protocolo
ERRADO:   feat(canvas): Adicionado speech bubble.   # maiúscula + ponto
ERRADO:   feat: atualização                          # sem scope, vago
```

---

## 4. BODY — Estrutura para o Nexus

```
feat(agentes): implementa Diretor fake com script de tarefa demo

- Agentes:
  * FakeDiretor implementa interface Agent (mesma do real)
  * Script: recebe tarefa → thinking 2s → delega para Implementer fake → resultado

- Protocolo:
  * Emite: agent.thinking, agent.speak, agent.move, agent.complete
  * Todos os eventos tipados de shared/events.ts
  * Frontend não sabe que é fake (princípio inegociável respeitado)

- Build:
  * frontend/: PASS
  * backend/: PASS
  * shared/: sem mudanças

- Documentation:
  * JSDoc em FakeDiretor.execute()
  * STATUS.md: Task 2 COMPLETE
```

---

## 5. EXEMPLOS COMPLETOS POR FASE

### Fase 0 — Fundação

```
chore(config): inicializa monorepo pnpm com workspaces frontend, backend e shared

- Config:
  * pnpm-workspace.yaml com três workspaces
  * tsconfig.json base com paths para shared/
  * Biome para lint e format em todos os workspaces

- Build:
  * Todos os workspaces compilam (vazio por ora)
```

```
feat(shared): define protocolo de eventos WebSocket v1

- Protocolo:
  * 8 eventos definidos: agent.move, agent.thinking, agent.speak,
    agent.status, agent.token, agent.complete, agent.error, task.start, task.complete
  * Tipos exportados para uso em frontend e backend
  * Sem breaking changes nesta versão

- Build:
  * shared/: PASS (npx tsc --noEmit)
```

```
feat(backend): implementa WebSocket com ping/pong via Socket.io

- Backend:
  * Fastify + @fastify/websocket
  * Socket.io integrado
  * Handler 'ping' → responde 'pong'
  * Logger pino configurado

- Build:
  * backend/: PASS
```

### Fase 1 — Agentes fake

```
feat(canvas): renderiza 3 agentes com animações idle e speech bubbles

- Canvas:
  * Game loop requestAnimationFrame com delta time
  * AgentStateManager fora do React state
  * Animações: idle (loop 4 frames), thinking (loop 2 frames)
  * SpeechBubbleManager com auto-dismiss
  * imageSmoothingEnabled = false em todos os ctx

- Performance:
  * 60fps estável com 3 agentes (medido)
  * Budget: <10ms por frame (update + draw)

- Build:
  * frontend/: PASS
```

### Fase 2 — Diretor real

```
feat(llm): abstrai provider LLM com suporte a Anthropic e Groq

- LLM:
  * Interface LLMProvider com complete() e stream()
  * AnthropicProvider implementa interface
  * GroqProvider implementa interface
  * Factory detecta ANTHROPIC_API_KEY / GROQ_API_KEY

- Segurança:
  * API keys apenas em process.env
  * Keys nunca logadas (pino)

- Build:
  * backend/: PASS
  * TypeScript: 0 errors
```

---

## ANTI-PADRÕES (Evitar)

```
# Vago
fix: bug no canvas

# Sem scope
feat: novo agente

# Mistura shared com implementação (deveriam ser commits separados)
feat(shared): adiciona evento + feat(backend): implementa handler

# Subject em inglês (equipe é BR)
feat(canvas): add speech bubble animation
```

---

## COMMITS ATÔMICOS NO NEXUS

Se mudou `shared/`, frontend E backend mudam **no mesmo commit** (ou commits em sequência rápida). Nunca deixar `shared/` na frente sem atualizar os dois lados — o repo ficaria com TypeScript errors.
