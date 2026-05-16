# Backend Implementer — Memória (Nexus)

## Stack e Build

**Workspace:** `backend/`
**Build:** `cd backend && npm run build`
**TypeScript:** `cd backend && npx tsc --noEmit`
**Framework:** Node.js + TypeScript + Fastify + Socket.io
**Validação:** Zod (todos os eventos recebidos do cliente)
**Logger:** pino (NUNCA console.log)
**LLMs:** Abstração via interface LLMProvider (Anthropic, Groq, OpenAI)
**Banco:** Prisma + PostgreSQL/SQLite (a partir da Fase 4)

## Regras Críticas

- Todos os agentes (fake e reais) implementam a mesma interface `Agent`
- Tipos de eventos importados de `../../shared/` — NUNCA redefinidos no backend
- Zod obrigatório em todos os eventos Socket.io recebidos do cliente
- Erros de agente viram eventos Socket.io (nunca silenciosos)
- API keys APENAS em process.env — nunca hardcoded, nunca logadas
- Socket.io rooms para isolamento por projeto: `project:${projectId}`

## Interface Agent (contrato central)

```typescript
interface Agent {
  readonly id: string;
  readonly name: string;
  execute(task: SubTask, emitter: AgentEventEmitter): Promise<AgentResult>;
}
```
Fake e real implementam exatamente isso — frontend nunca sabe qual é qual.

## Os 7 Agentes do MVP

IDs: 'diretor', 'estrategista', 'documenter', 'arquiteto', 'implementer', 'reviewer', 'designer'
(System prompts a definir e versionar)

## Estrutura do Orquestrador

(Preencher após implementação)

## LLM Providers

(Preencher após implementação — particularidades de cada provider)

## Eventos Socket.io — Direções

(Preencher após shared/ ser definida)

## Gotchas de Fastify + Socket.io

(Preencher após implementação)
