# Padrões Nexus — Backend + Shared

**Aplicável a:** `backend/`, `shared/` e decisões de arquitetura do Nexus.

---

## 1. PROTOCOLO DE EVENTOS — REGRA FUNDAMENTAL

### shared/ é a fonte única de verdade

```typescript
// ERRADO — evento definido no backend
// backend/src/handlers/agent.ts
type AgentSpeakPayload = { text: string; agentId: string };

// ERRADO — evento definido no frontend
// frontend/src/socket/events.ts
interface AgentSpeakEvent { text: string }

// CORRETO — definido em shared/, importado nos dois lados
// shared/src/events.ts
export interface AgentSpeakEvent {
  agentId: string;
  text: string;
  duration: number; // ms para o speech bubble ficar visível
}

// backend usa:
import type { AgentSpeakEvent } from '../../shared/src/events';
socket.emit('agent.speak', payload satisfies AgentSpeakEvent);

// frontend usa:
import type { AgentSpeakEvent } from '../../shared/src/events';
socket.on('agent.speak', (event: AgentSpeakEvent) => { ... });
```

### Mudança no protocolo = commit coordenado

Se `shared/` muda, frontend E backend mudam no **mesmo commit**. Nunca em commits separados — o repo ficaria inconsistente.

---

## 2. INTERFACE DE AGENTES — FAKE = REAL

### Mesma interface, cérebros diferentes

```typescript
// shared/src/agents.ts — contrato público
export interface SubTask {
  id: string;
  description: string;
  context?: string;
}

export interface AgentResult {
  agentId: string;
  output: string;
  tokensUsed?: number;
}

// Interface que TODOS implementam
export interface Agent {
  readonly id: string;
  readonly name: string;
  execute(task: SubTask, emitter: AgentEventEmitter): Promise<AgentResult>;
}
```

```typescript
// Agente fake (Fase 1) — scriptado
export class FakeDiretor implements Agent {
  readonly id = 'diretor';
  readonly name = 'Marina, Diretora';

  async execute(task: SubTask, emitter: AgentEventEmitter): Promise<AgentResult> {
    emitter.thinking(this.id, 2000);
    await sleep(2000);
    emitter.speak(this.id, 'Analisando a tarefa...', 2000);
    await sleep(2000);
    // ... script
    return { agentId: this.id, output: 'resultado mockado' };
  }
}

// Agente real (Fase 2+) — LLM
export class RealDiretor implements Agent {
  readonly id = 'diretor';
  readonly name = 'Marina, Diretora';

  constructor(private llm: LLMProvider) {}

  async execute(task: SubTask, emitter: AgentEventEmitter): Promise<AgentResult> {
    emitter.thinking(this.id, 0);
    let fullResponse = '';
    for await (const token of this.llm.stream([{ role: 'user', content: task.description }])) {
      fullResponse += token;
      emitter.token(this.id, token);
    }
    emitter.speak(this.id, 'Concluído', 2000);
    return { agentId: this.id, output: fullResponse };
  }
}
```

---

## 3. ABSTRAÇÃO DE LLM PROVIDER

```typescript
// shared/src/llm.ts
export interface Message {
  role: 'user' | 'assistant' | 'system';
  content: string;
}

export interface LLMOptions {
  temperature?: number;
  maxTokens?: number;
}

export interface LLMProvider {
  complete(messages: Message[], options?: LLMOptions): Promise<string>;
  stream(messages: Message[], options?: LLMOptions): AsyncIterable<string>;
  estimateTokens(messages: Message[]): number;
}
```

```typescript
// backend/src/llm/anthropic.provider.ts
import Anthropic from '@anthropic-ai/sdk';
import type { LLMProvider, Message, LLMOptions } from '../../shared/src/llm';

export class AnthropicProvider implements LLMProvider {
  private client: Anthropic;

  constructor() {
    // NUNCA hardcode a key
    this.client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
  }

  async *stream(messages: Message[], options?: LLMOptions): AsyncIterable<string> {
    const stream = await this.client.messages.stream({
      model: 'claude-sonnet-4-6',
      max_tokens: options?.maxTokens ?? 4096,
      messages: messages.map(m => ({ role: m.role, content: m.content })),
    });
    for await (const event of stream) {
      if (event.type === 'content_block_delta' && event.delta.type === 'text_delta') {
        yield event.delta.text;
      }
    }
  }

  async complete(messages: Message[], options?: LLMOptions): Promise<string> {
    let result = '';
    for await (const token of this.stream(messages, options)) {
      result += token;
    }
    return result;
  }

  estimateTokens(messages: Message[]): number {
    // Estimativa rápida: ~4 chars por token
    const totalChars = messages.reduce((sum, m) => sum + m.content.length, 0);
    return Math.ceil(totalChars / 4);
  }
}
```

---

## 4. VALIDAÇÃO DE EVENTOS — ZOD OBRIGATÓRIO

Todo evento recebido do cliente (Socket.io ou HTTP) DEVE ser validado com Zod:

```typescript
import { z } from 'zod';

const TaskSubmitSchema = z.object({
  projectId: z.string().uuid(),
  description: z.string().min(1).max(2000),
  tokenCap: z.number().int().positive().max(100_000).optional(),
});

// Handler Socket.io
socket.on('task.submit', (data: unknown) => {
  const result = TaskSubmitSchema.safeParse(data);
  if (!result.success) {
    socket.emit('error', {
      code: 'INVALID_INPUT',
      issues: result.error.issues,
    });
    return;
  }
  // result.data é type-safe
  orchestrator.handleTask(result.data, socket);
});
```

---

## 5. SOCKET.IO — ROOMS POR PROJETO

```typescript
// Cada projeto tem sua room — eventos não vazam entre projetos
const roomId = `project:${projectId}`;

// Socket entra na room ao selecionar projeto
socket.join(roomId);

// Orquestrador emite para room específica
io.to(roomId).emit('agent.move', event satisfies AgentMoveEvent);

// Ao sair do projeto, sai da room
socket.leave(roomId);
```

---

## 6. ERROR HANDLING — ERROS VIRAM EVENTOS

Erros de agente nunca devem ser silenciosos — o frontend precisa saber para atualizar a UI:

```typescript
// ERRADO — erro silencioso
async function runAgent(agent: Agent, task: SubTask) {
  try {
    await agent.execute(task, emitter);
  } catch (e) {
    console.error(e); // frontend não sabe
  }
}

// CORRETO — erro vira evento
async function runAgent(agent: Agent, task: SubTask, socket: Socket) {
  try {
    const result = await agent.execute(task, createEmitter(socket));
    socket.emit('agent.complete', { agentId: agent.id, result } satisfies AgentCompleteEvent);
  } catch (err) {
    logger.error({ err, agentId: agent.id }, 'Agent execution failed');
    socket.emit('agent.error', {
      agentId: agent.id,
      message: err instanceof Error ? err.message : 'Erro desconhecido',
      recoverable: isRecoverableError(err),
    } satisfies AgentErrorEvent);
  }
}
```

---

## 7. LOGGING — PINO, NUNCA CONSOLE.LOG

```typescript
import pino from 'pino';

const logger = pino({
  level: process.env.LOG_LEVEL ?? 'info',
});

// CORRETO
logger.info({ agentId, taskId, tokensUsed }, 'Agent completed task');
logger.error({ err, agentId }, 'Agent failed');
logger.debug({ event }, 'Socket event received');

// ERRADO
console.log('Agent completed'); // perde estrutura, perde stacktrace
```

### NÃO logar dados sensíveis
```typescript
// ERRADO — expõe API key nos logs
logger.info({ apiKey: process.env.ANTHROPIC_API_KEY }, 'Provider initialized');

// CORRETO
logger.info({ provider: 'anthropic' }, 'Provider initialized');
```

---

## 8. SEGURANÇA BÁSICA

### API Keys
```typescript
// NUNCA hardcoded
// NUNCA logadas
// SEMPRE de process.env

// ERRADO
const client = new Anthropic({ apiKey: 'sk-ant-...' });

// CORRETO
if (!process.env.ANTHROPIC_API_KEY) {
  throw new Error('ANTHROPIC_API_KEY não configurada');
}
const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
```

### TypeScript strict — zero `any`
```typescript
// ERRADO
function handleEvent(data: any) { data.whatever(); }

// CORRETO — Zod faz o parse, TypeScript garante o tipo
function handleEvent(data: unknown) {
  const parsed = EventSchema.parse(data); // lança se inválido
  // parsed é type-safe
}
```

---

## 9. PERFORMANCE — STREAMING CONSCIENTE

```typescript
// Streaming token-a-token via Socket.io
// Cuidado: cada emit é uma mensagem — não emitir demais
// Estratégia: batching de tokens (a cada 50ms ou X tokens)

class TokenBatcher {
  private buffer = '';
  private timer: NodeJS.Timeout | null = null;

  constructor(
    private emitter: (token: string) => void,
    private intervalMs = 50,
  ) {}

  push(token: string) {
    this.buffer += token;
    if (!this.timer) {
      this.timer = setTimeout(() => {
        this.flush();
      }, this.intervalMs);
    }
  }

  flush() {
    if (this.buffer) {
      this.emitter(this.buffer);
      this.buffer = '';
    }
    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = null;
    }
  }
}
```

---

## 10. CHECKLIST DE QUALIDADE (BACKEND/SHARED)

- [ ] Build passa (`npm run build` em backend/ e shared/)
- [ ] TypeScript 0 errors
- [ ] Todos os tipos de eventos vêm de `shared/`
- [ ] Agentes fake e reais implementam a mesma interface
- [ ] Zod validação em todos os eventos recebidos do cliente
- [ ] Erros de agente viram eventos Socket.io
- [ ] Nenhum `console.log` — pino
- [ ] API keys só em `process.env`, nunca logadas
- [ ] Socket.io rooms usadas para isolamento de projetos
- [ ] Zero `any` injustificado
- [ ] Imports organizados (libs externas → shared → internos → types)
