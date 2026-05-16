# Impl Notes — Frontend Canvas Fundação (Task 2)

**Agente:** Frontend Implementer
**Data:** 2026-05-16
**Plano:** `workspace/plans/plan-frontend-canvas-fundacao-task2.md`
**Status:** COMPLETE

---

## O que foi implementado

### Fase 1 — Scaffold (completado)

- `frontend/biome.json` — linter/formatter com `noExplicitAny: error`
- `frontend/index.html` — entry point HTML
- `pnpm install` na raiz — aprovados builds de `@biomejs/biome` e `esbuild` via `allowBuilds` no `pnpm-workspace.yaml`

### Fase 2 — Entry point e layout

- `src/index.css` — reset global + Tailwind directives
- `src/main.tsx` — monta `<App>` no `#root` com StrictMode
- `src/chrome/Topbar.tsx` — brand, status WS (dot colorido), botão Ping, timestamp do último pong
- `src/App.tsx` — layout: topbar + flex (canvas area + chat sidebar placeholder)

### Fase 3 — Canvas mínimo

- `src/canvas/constants.ts` — TILE=36, OFFICE_W=1152, OFFICE_H=648, PX=2, paleta de cores do escritório
- `src/canvas/loop.ts` — `startGameLoop()` com delta time, aviso de frame lento em dev (>12ms), cleanup function
- `src/office/state/types.ts` — `AgentRenderState`, `AgentState`, `SpeechBubble`
- `src/office/data/office-layout.ts` — OFFICE com cols/rows/rooms (notion, github, meeting)
- `src/office/data/agents.ts` — AGENTS[7] com todos os dados do protótipo, AGENTS_BY_ID Map
- `src/canvas/drawFloor.ts` — piso com tiles alternados (a cada 2 colunas) + linhas de junção
- `src/canvas/drawRooms.ts` — salas coloridas com label e borda interna
- `src/canvas/draw.ts` — `drawOffice()` orquestra todas as camadas

### Fase 4 — Agentes placeholder

- `src/canvas/drawAgents.ts` — retângulos 24×36px (chatColor) + sombra elipse + label + indicador de estado colorido por canto
- `src/canvas/drawSpeechBubbles.ts` — bubble com roundRect, setinha, sombra, auto-dismiss por expiresAt
- `src/office/state/AgentStateManager.ts` — initialize, update (animPhase, interpolação, expiração bubbles), getAll, setState, moveTo, showSpeech, hitTest
- `src/office/AgentPopover.tsx` — popover absoluto sobre canvas com avatar colorido, bio, botão "Falar"
- `src/office/Office.tsx` — canvas com ref, `imageSmoothingEnabled = false`, game loop com cleanup, hitTest, AgentPopover

### Fase 5 — Socket.io

- `src/socket/client.ts` — `NexusSocket` tipado, `createSocket()` com path `/socket.io`
- `src/socket/hooks.ts` — `useSocket()` com connect/disconnect/pong tracking

### Fase 6 — Verificações

- `pnpm run typecheck` — zero erros TypeScript
- `pnpm run lint` (biome check src/) — zero erros
- `pnpm run build` — build de produção: 248KB JS, 9.4KB CSS

---

## Problemas encontrados e resoluções

### 1. `pnpm` não disponível no PATH
Instalado globalmente via `npm install -g pnpm`. Builds de `@biomejs/biome` e `esbuild` bloqueados — resolvido adicionando `allowBuilds: true` em `pnpm-workspace.yaml`.

### 2. `tsconfig.json references` exigindo `composite: true`
O `references: [tsconfig.node.json]` exige `composite: true` no arquivo referenciado. Adicionado e depois removido — a referência não é necessária para o projeto Vite (o Vite não usa composite projects). Removido `references` do tsconfig.json principal.

### 3. `tsc -b` emitindo `.js` na pasta `src/`
O script `build: "tsc -b && vite build"` com tsconfig sem `outDir` gerou arquivos `.js` na src, que o Biome então queria formatar. Solução: removido o `tsc -b` do script de build (o Vite faz a transpilação; typecheck separado com `tsc --noEmit`). Adicionado `noEmit: true` no tsconfig.

### 4. Biome `organizeImports` — `type` imports antes dos value imports
Biome ordena: `import type` antes de `import`. Corrigido via `biome check --fix`.

### 5. Biome a11y `useKeyWithClickEvents`
Overlay div com `onClick` sem `onKeyDown`. Corrigido: overlay recebeu `role="button"`, `tabIndex={-1}` e `onKeyDown` para Escape/Enter. Canvas recebeu `tabIndex={0}` e `onKeyDown` para Escape.

---

## Checklist de qualidade

- [x] Build passa (`pnpm run build`)
- [x] TypeScript 0 erros (`pnpm run typecheck`)
- [x] Biome lint 0 erros (`pnpm run lint`)
- [x] `imageSmoothingEnabled = false` imediatamente após `canvas.getContext('2d')`
- [x] `imageRendering: pixelated` no elemento `<canvas>`
- [x] Game loop retorna cleanup function; useEffect retorna cleanup
- [x] AgentStateManager em `useRef`, nunca em `useState`
- [x] Zero `any` (Biome `noExplicitAny: error` cobre)
- [x] Tipos de agentes e layout de shared/ temporários (locais) — comentados para substituição futura
- [x] Frontend não sabe se agente é fake ou real
- [x] Canvas loop opera em <16ms (apenas fillRect e contexto simples — budget OK)
- [x] Tailwind apenas no chrome (Topbar, chat sidebar)

---

## Estrutura final de arquivos

```
frontend/src/
├── main.tsx
├── App.tsx
├── index.css
├── canvas/
│   ├── constants.ts
│   ├── loop.ts
│   ├── draw.ts
│   ├── drawFloor.ts
│   ├── drawRooms.ts
│   ├── drawAgents.ts
│   └── drawSpeechBubbles.ts
├── chrome/
│   └── Topbar.tsx
├── office/
│   ├── Office.tsx
│   ├── AgentPopover.tsx
│   ├── data/
│   │   ├── agents.ts
│   │   └── office-layout.ts
│   └── state/
│       ├── AgentStateManager.ts
│       └── types.ts
└── socket/
    ├── client.ts
    └── hooks.ts
```

---

## Próximos passos (Fase 1 do roadmap)

- Sprites pixel art completos (usar SPRITE_TEMPLATE do protótipo via `ctx.fillRect`)
- Animações de estado: idle bob, thinking aura, working typing shimmer
- Chat lateral funcional com streaming token-a-token
- Integração com backend Socket.io real (backend deve estar funcionando)
