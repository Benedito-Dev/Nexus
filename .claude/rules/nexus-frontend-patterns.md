# Padrões Nexus — Frontend (Canvas + React + Socket.io)

**Aplicável a:** `frontend/` do Nexus.

---

## 1. CANVAS — GAME LOOP CORRETO

### requestAnimationFrame com delta time

```typescript
// frontend/src/canvas/loop.ts

export function startGameLoop(
  ctx: CanvasRenderingContext2D,
  update: (delta: number) => void,
  draw: (ctx: CanvasRenderingContext2D) => void,
): () => void {
  let lastTime = 0;
  let rafId: number;

  function loop(timestamp: number) {
    const delta = lastTime === 0 ? 16 : timestamp - lastTime; // ms
    lastTime = timestamp;

    // Limpa o frame anterior
    ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);

    update(delta);
    draw(ctx);

    rafId = requestAnimationFrame(loop);
  }

  rafId = requestAnimationFrame(loop);

  // Retorna cleanup function
  return () => cancelAnimationFrame(rafId);
}
```

### Budget: 60fps com 8 agentes

```typescript
// update() e draw() DEVEM completar em <16ms juntos
// Medição:
const start = performance.now();
update(delta);
draw(ctx);
const elapsed = performance.now() - start;
if (elapsed > 12) {
  console.warn(`Frame lento: ${elapsed.toFixed(1)}ms`); // só em dev
}
```

---

## 2. PIXEL ART — SEM INTERPOLAÇÃO

```typescript
// SEMPRE ao inicializar o canvas
const ctx = canvas.getContext('2d')!;
ctx.imageSmoothingEnabled = false;

// CSS — evita blur no scaling
canvas.style.imageRendering = 'pixelated';
// ou em Tailwind: className="[image-rendering:pixelated]"
```

---

## 3. ESTADO DE AGENTES — FORA DO REACT

O estado que muda a 60fps (posição, animação frame) nunca deve ser React state.
React state só para o que a UI lateral precisa (nome, status textual, hover).

```typescript
// ERRADO — re-render a 60fps mata performance
const [agents, setAgents] = useState<Agent[]>([]);
// No update loop:
setAgents(prev => prev.map(a => ({ ...a, x: a.x + dx }))); // 60x/s!

// CORRETO — estado mutável no manager
class AgentStateManager {
  private states = new Map<string, AgentRenderState>();

  update(id: string, delta: number) {
    const state = this.states.get(id);
    if (!state) return;
    // atualiza posição, frame de animação, etc.
    state.x += state.vx * delta;
    state.animFrame = Math.floor(Date.now() / 200) % state.totalFrames;
  }

  getAll(): AgentRenderState[] {
    return [...this.states.values()];
  }
}

// React só para estado de UI (nome no popover, etc.)
const [selectedAgent, setSelectedAgent] = useState<string | null>(null);
```

---

## 4. CANVAS COM REACT — PADRÃO DE REF

```typescript
// frontend/src/components/Office.tsx

import { useEffect, useRef } from 'react';
import { startGameLoop } from '../canvas/loop';
import { AgentStateManager } from '../canvas/agents';
import { drawOffice } from '../canvas/draw';

export function Office() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const managerRef = useRef(new AgentStateManager());

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d')!;
    ctx.imageSmoothingEnabled = false;

    const manager = managerRef.current;

    const cleanup = startGameLoop(
      ctx,
      (delta) => manager.update(delta),
      (ctx) => drawOffice(ctx, manager.getAll()),
    );

    return cleanup; // para o loop ao desmontar
  }, []);

  return (
    <canvas
      ref={canvasRef}
      width={1280}
      height={720}
      className="[image-rendering:pixelated]"
    />
  );
}
```

---

## 5. SOCKET.IO CLIENT — PROTOCOLO COMO CONTRATO

```typescript
// frontend/src/socket/client.ts

import { io, Socket } from 'socket.io-client';
import type {
  AgentMoveEvent,
  AgentSpeakEvent,
  AgentThinkingEvent,
  AgentTokenEvent,
  AgentCompleteEvent,
  AgentErrorEvent,
  TaskStartEvent,
} from '../../../shared/src/events';

// Tipagem do socket — garante que eventos seguem o protocolo
interface ServerToClientEvents {
  'agent.move': (event: AgentMoveEvent) => void;
  'agent.speak': (event: AgentSpeakEvent) => void;
  'agent.thinking': (event: AgentThinkingEvent) => void;
  'agent.token': (event: AgentTokenEvent) => void;
  'agent.complete': (event: AgentCompleteEvent) => void;
  'agent.error': (event: AgentErrorEvent) => void;
  'task.start': (event: TaskStartEvent) => void;
}

interface ClientToServerEvents {
  'task.submit': (data: { projectId: string; description: string }) => void;
}

// Socket tipado — TypeScript garante conformidade com o protocolo
export type NexusSocket = Socket<ServerToClientEvents, ClientToServerEvents>;

export function createSocket(url: string): NexusSocket {
  return io(url) as NexusSocket;
}
```

---

## 6. SPEECH BUBBLES — CURTAS E REAIS

```typescript
// Texto máximo: 40 chars visíveis
// Auto-dismiss após duration
// Reflete status REAL do agente (não texto inventado)

interface SpeechBubble {
  agentId: string;
  text: string;
  expiresAt: number; // Date.now() + duration
}

class SpeechBubbleManager {
  private bubbles = new Map<string, SpeechBubble>();

  show(agentId: string, text: string, durationMs: number) {
    // Truncar se necessário
    const displayText = text.length > 40 ? text.slice(0, 37) + '...' : text;
    this.bubbles.set(agentId, {
      agentId,
      text: displayText,
      expiresAt: Date.now() + durationMs,
    });
  }

  update() {
    const now = Date.now();
    for (const [id, bubble] of this.bubbles) {
      if (bubble.expiresAt <= now) {
        this.bubbles.delete(id);
      }
    }
  }

  getActive(): SpeechBubble[] {
    return [...this.bubbles.values()];
  }
}
```

---

## 7. STREAMING — CHAT LATERAL, NÃO CANVAS

```typescript
// Token-a-token vai pro chat lateral (React component)
// Canvas só mostra status curto (speech bubble)

// frontend/src/components/ChatPanel.tsx
import { useState, useCallback } from 'react';

export function ChatPanel({ socket }: { socket: NexusSocket }) {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [streamBuffer, setStreamBuffer] = useState('');

  useEffect(() => {
    socket.on('agent.token', (event) => {
      // Acumula tokens no buffer (UI atualizada a cada token)
      setStreamBuffer(prev => prev + event.token);
    });

    socket.on('agent.complete', (event) => {
      // Move buffer para mensagem finalizada
      setMessages(prev => [...prev, {
        agentId: event.agentId,
        content: streamBuffer + event.result.output,
        timestamp: Date.now(),
      }]);
      setStreamBuffer('');
    });

    return () => {
      socket.off('agent.token');
      socket.off('agent.complete');
    };
  }, [socket, streamBuffer]);

  // ...render
}
```

---

## 8. HOOK CUSTOMIZADO — SOCKET.IO

```typescript
// frontend/src/hooks/useSocket.ts

import { useEffect, useRef, useState } from 'react';
import { createSocket, type NexusSocket } from '../socket/client';

export function useSocket(url: string) {
  const socketRef = useRef<NexusSocket | null>(null);
  const [connected, setConnected] = useState(false);

  useEffect(() => {
    const socket = createSocket(url);
    socketRef.current = socket;

    socket.on('connect', () => setConnected(true));
    socket.on('disconnect', () => setConnected(false));

    return () => {
      socket.disconnect();
      socketRef.current = null;
    };
  }, [url]);

  return { socket: socketRef.current, connected };
}
```

---

## 9. TYPESCRIPT STRICT NO FRONTEND

```typescript
// Zero `any` — tipos vêm de shared/ ou são inferidos
// ERRADO
const agentData: any = socketEvent.data;

// CORRETO — importar tipo de shared/
import type { AgentMoveEvent } from '../../../shared/src/events';
socket.on('agent.move', (event: AgentMoveEvent) => {
  agentManager.moveTo(event.agentId, event.x, event.y);
});
```

---

## 10. TAILWIND — APENAS PARA CHROME

Canvas: renderizado programaticamente (não CSS)
Tailwind: UI lateral, overlays, modais, popover de agente

```typescript
// Estrutura da tela
<div className="flex h-screen bg-gray-900">
  {/* Canvas — ocupa a maior parte */}
  <canvas ref={canvasRef} className="flex-1 [image-rendering:pixelated]" />

  {/* Chrome lateral — Tailwind */}
  <aside className="w-80 bg-gray-800 flex flex-col border-l border-gray-700">
    <ChatPanel socket={socket} />
  </aside>
</div>
```

---

## 11. CHECKLIST DE QUALIDADE (FRONTEND)

- [ ] Build passa (`npm run build` em `frontend/`)
- [ ] TypeScript 0 errors (`npx tsc --noEmit`)
- [ ] `imageSmoothingEnabled = false` em todo ctx com sprites
- [ ] Canvas CSS: `image-rendering: pixelated`
- [ ] Estado de posição/animação fora do React state
- [ ] Tipos de eventos importados de `shared/`, nunca redefinidos
- [ ] Socket tipado (`Socket<ServerToClientEvents, ClientToServerEvents>`)
- [ ] Speech bubbles: texto ≤40 chars, reflete status real
- [ ] Streaming token-a-token no chat, não no Canvas
- [ ] Zero `any` injustificado
- [ ] Canvas loop retorna cleanup function (evita memory leak)
- [ ] 60fps não comprometido (sem ops pesadas no loop de render)
