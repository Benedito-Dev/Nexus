---
name: project-canvas-structure
description: Estrutura do Canvas implementada na Fase 0 — game loop, managers, layers, componentes React
metadata:
  type: project
---

Estrutura do Canvas implementada na Task 2 (Fase 0 do roadmap).

**Game loop:** `src/canvas/loop.ts` — `startGameLoop(ctx, update, draw)` retorna cleanup function. Delta time com fallback de 16ms no primeiro frame. Aviso de frame lento (>12ms) apenas em dev.

**Layers (ordem de draw):**
1. `drawFloor` — piso com tiles alternados a cada 2 colunas
2. `drawRooms` — salas notion/github/meeting com cores e labels
3. `drawAgents` — retângulos coloridos (Fase 0; sprites pixel art na Fase 1)
4. `drawSpeechBubbles` — bubbles com roundRect, setinha e sombra

**AgentStateManager:** `src/office/state/AgentStateManager.ts`
- Em `useRef` no Office.tsx — NUNCA em useState
- Inicializado com `AGENTS[]` em posição home (tiles → pixels = tile * TILE)
- `update(delta)` avança animPhase, interpola posição, expira bubbles
- `hitTest(px, py)` retorna id do agente clicado por bounding box SPRITE_W×SPRITE_H

**Office.tsx:** Único componente que toca Canvas API
- `imageSmoothingEnabled = false` imediatamente após `getContext('2d')`
- Cleanup retornado do useEffect (para o loop no unmount)
- Click handler calcula posição relativa ao canvas e chama `manager.hitTest()`
- AgentPopover posicionado com `state.x` e `state.y - SPRITE_H`

**Dados dos agentes:** `src/office/data/agents.ts` — 7 agentes com home/desk/chatColor/sprite palette
**Layout:** `src/office/data/office-layout.ts` — 32×18 tiles, 3 salas especiais

**pnpm:** Instalado via `npm install -g pnpm`. Binary: `$env:APPDATA\npm\pnpm.cmd`. Builds aprovados em `pnpm-workspace.yaml` (allowBuilds: @biomejs/biome, esbuild).

**Why:** Decisão de usar Canvas API pura (sem PixiJS) é inegociável — definida em nexus-contexto.md seção 8.1.

**How to apply:** Ao adicionar features de canvas, seguir as layers em ordem. Novo estado de agente vai no AgentStateManager, nunca em React state.
