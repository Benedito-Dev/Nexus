# JSDoc Templates — Nexus (TypeScript)

Templates para documentar o código do Nexus de forma consistente.

---

## 1. AGENTE (Interface + Implementação)

```typescript
/**
 * Agente fake scriptado para a Fase 1 do Nexus.
 *
 * Implementa a interface Agent com comportamento pré-programado.
 * Emite os MESMOS eventos Socket.io que o agente real — frontend
 * não distingue entre fake e real (princípio fundamental do Nexus).
 *
 * @example
 * const diretor = new FakeDiretor();
 * await diretor.execute(task, emitter);
 */
export class FakeDiretor implements Agent {
  /**
   * Executa a tarefa com comportamento scriptado.
   *
   * Sequência de eventos emitidos:
   * 1. `agent.thinking` — 2s de "reflexão"
   * 2. `agent.speak` — "Analisando a tarefa..."
   * 3. `agent.move` — move para mesa do Implementer
   * 4. `agent.complete` — retorna resultado mockado
   *
   * @param task - Subtarefa a executar
   * @param emitter - Emitter para eventos Socket.io
   * @returns Resultado mockado da execução
   */
  async execute(task: SubTask, emitter: AgentEventEmitter): Promise<AgentResult> { ... }
}
```

---

## 2. CANVAS FUNCTIONS

```typescript
/**
 * Renderiza todos os agentes visíveis no canvas.
 *
 * Deve ser chamada dentro do game loop (requestAnimationFrame).
 * Opera em <5ms para manter budget de 16ms/frame (60fps).
 *
 * @param ctx - Contexto 2D do canvas (imageSmoothingEnabled deve ser false)
 * @param agents - Estados atuais dos agentes para renderizar
 */
function drawAgents(ctx: CanvasRenderingContext2D, agents: AgentRenderState[]): void { ... }

/**
 * Atualiza posições e animações dos agentes.
 *
 * @param agents - Map mutável de estados de agentes
 * @param delta - Tempo em ms desde o último frame (tipicamente 16ms)
 */
function updateAgents(agents: Map<string, AgentRenderState>, delta: number): void { ... }
```

---

## 3. SOCKET.IO HANDLERS

```typescript
/**
 * Registra handlers de Socket.io para o Orquestrador.
 *
 * Eventos escutados (client→server):
 * - `task.submit` — usuário submete nova tarefa
 * - `task.interrupt` — usuário interrompe tarefa em andamento
 *
 * Eventos emitidos (server→client) via Orquestrador:
 * - `agent.*` — eventos de estado dos agentes
 * - `task.start` / `task.complete` — ciclo da tarefa
 *
 * @param io - Instância do Socket.io Server
 * @param orchestrator - Orquestrador de agentes
 */
function registerOrchestratorHandlers(io: Server, orchestrator: Orchestrator): void { ... }
```

---

## 4. LLM PROVIDER

```typescript
/**
 * Provider Anthropic para o LLM do Nexus.
 *
 * Implementa LLMProvider com streaming token-a-token.
 * API key lida de ANTHROPIC_API_KEY (nunca hardcoded).
 *
 * @example
 * const provider = new AnthropicProvider();
 * for await (const token of provider.stream(messages)) {
 *   emitter.token(agentId, token);
 * }
 */
export class AnthropicProvider implements LLMProvider {
  /**
   * Streaming de resposta token-a-token.
   *
   * @param messages - Histórico de mensagens (system + conversation)
   * @param options - Configurações opcionais (temperatura, max tokens)
   * @yields Tokens individuais da resposta
   * @throws {LLMError} Se a API retornar erro após retries
   */
  async *stream(messages: Message[], options?: LLMOptions): AsyncIterable<string> { ... }
}
```

---

## 5. TIPOS DO PROTOCOLO (shared/)

```typescript
/**
 * Evento emitido quando um agente se movimenta no escritório.
 *
 * Direção: server → client
 * Emitido por: Orquestrador ao atualizar posição de agente
 */
export interface AgentMoveEvent {
  /** ID único do agente (ex: 'diretor', 'implementer') */
  agentId: string;
  /** Posição X destino em pixels do mapa */
  x: number;
  /** Posição Y destino em pixels do mapa */
  y: number;
  /** Duração do movimento em ms (para animação suave) */
  duration: number;
}

/**
 * Evento emitido quando agente está "pensando" (processando).
 *
 * Direção: server → client
 * No frontend: exibe animação de thinking no agente
 */
export interface AgentThinkingEvent {
  agentId: string;
  /** 0 para duração indefinida (agente real processando LLM) */
  duration: number;
}
```

---

## 6. REACT COMPONENTS (chrome lateral)

```typescript
/**
 * Painel de chat lateral do Nexus.
 *
 * Exibe mensagens dos agentes com streaming token-a-token.
 * Único ponto de interação textual do usuário com o Nexus.
 *
 * @param socket - Socket.io tipado com eventos do protocolo Nexus
 */
export function ChatPanel({ socket }: { socket: NexusSocket }): JSX.Element { ... }

/**
 * Popover exibido ao clicar em um agente no Canvas.
 *
 * Exibe status atual e botão "Falar com ele" (adiciona @NomeAgente no chat).
 *
 * @param agent - Dados do agente clicado
 * @param onTalkTo - Callback que injeta @NomeAgente no input do chat
 * @param onClose - Fecha o popover
 */
export function AgentPopover({
  agent,
  onTalkTo,
  onClose,
}: AgentPopoverProps): JSX.Element { ... }
```

---

## QUANDO DOCUMENTAR NO NEXUS

- [ ] **SEMPRE:** Interface `Agent` e todos que a implementam
- [ ] **SEMPRE:** Tipos de eventos em `shared/` (protocolo público)
- [ ] **SEMPRE:** Funções públicas de Canvas (`draw*`, `update*`)
- [ ] **SEMPRE:** LLM Providers e seus métodos de stream
- [ ] **RECOMENDADO:** Handlers Socket.io (quais eventos escuta/emite)
- [ ] **RECOMENDADO:** React components públicos (props documentadas)
- [ ] **OPCIONAL:** Funções privadas de Canvas (só se lógica não-óbvia)
- [ ] **EVITAR:** Getters triviais, funções auto-explicativas
