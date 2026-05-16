# Strategist Agent — Memória (Nexus)

## Projeto

**Nome:** Nexus
**Domínio:** Plataforma visual de orquestração de múltiplos agentes IA
**Stack:** React + Vite + Canvas API (frontend) | Node.js + TypeScript + Fastify + Socket.io (backend) | shared/ (protocolo de eventos TS)
**Monorepo:** pnpm, estrutura flat (frontend/, backend/, shared/)
**Fase atual:** 0 — Fundação (não iniciada)

## Princípios Inegociáveis (nunca violar no planejamento)

1. Agentes fake e reais usam o MESMO protocolo de eventos — frontend nunca sabe qual é qual
2. Schema de eventos vive em `shared/` — mudança = breaking change em ambos os lados
3. Projeto é unidade de contexto isolada (Socket.io rooms)
4. Mesma engine, dois figurinos (personalidade = troca de system prompt, não código)
5. Status real no speech bubble — não teatro

## Caso de Uso Âncora

"Nexus, busca no Notion toda a documentação sobre o projeto X, enriquece com fontes da internet, passa pro Implementer escrever um código base mockado seguindo o Design System do agente Designer, e sobe num repositório GitHub."

Todo plano deve ser medido contra esse fluxo.

## Os 7 Agentes do MVP

Diretor (Marina), Estrategista, Documenter, Arquiteto, Implementer, Reviewer, Designer.
Nota: Estrategista e Arquiteto podem se sobrepor — observar em uso real, considerar fusão.

## Roadmap (6 Fases)

- Fase 0: Fundação (canvas vazio, websocket, protocolo)
- Fase 1: Agentes fake animados ("demo do uau")
- Fase 2: Primeiro agente real (Diretor)
- Fase 3: Time completo real
- Fase 4: Persistência e projetos (Prisma + PostgreSQL)
- Fase 5: Integrações reais (Notion MCP, GitHub MCP)
- Fase 6: Pronto para usuários (auth, BYOK, billing, deploy)

## Decisões Arquiteturais Registradas

### 2026-05-16 — Stack backend: Node.js + TypeScript (não Python)
- Motivo: protocolo de eventos é o coração; em Node+TS vive em pacote único
- Divergência no shared/ = erro de compilação (TypeScript garante)
- Socket.io mais maduro; MCP first-class em TS; uma linguagem só

### 2026-05-16 — Monorepo flat (não apps/ + packages/)
- Motivo: só 3 workspaces — aninhar atrapalha navegação e paths
- Se crescer pra múltiplos apps/packages: reorganizar depois (custo baixo)

## Riscos Conhecidos

- Latência LLM matando imersão (3-30s) → streaming + animações
- Custo de 4-6 agentes por tarefa → BYOK + estimativa + cap
- Complexidade do orquestrador → workflow linear primeiro
- Canvas pesado → budget 60fps desde o início
- Estrategista vs Arquiteto sobrepostos → observar uso real
- Desincronização frontend/backend → monorepo + shared/ + TS estrito

## Patterns de Plan que Funcionam

(Preencher após primeiras tasks)

## Bounded Contexts

- `shared/` → consumido por frontend E backend (nunca modificar sem atualizar os dois lados)
- `frontend/` → Canvas + React + Socket.io client
- `backend/` → Fastify + Socket.io server + agentes + LLM providers
- Fase 4+: Prisma + PostgreSQL entram no backend
