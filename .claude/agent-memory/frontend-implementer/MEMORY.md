# Frontend Implementer — Memória (Nexus)

## Stack e Build

**Workspace:** `frontend/`
**Build:** `pnpm run build` (apenas `vite build` — NÃO `tsc -b && vite build`)
**TypeScript:** `pnpm run typecheck` (`tsc --noEmit`)
**Lint:** `./node_modules/.bin/biome check src/` (biome binary local)
**Auto-fix:** `./node_modules/.bin/biome check --fix src/`
**pnpm binary:** `$env:APPDATA\npm\pnpm.cmd` (PowerShell) — instalado via `npm install -g pnpm`
**Framework:** React 19 + Vite 6 + TypeScript 5.8 strict
**Renderização:** Canvas API pura (game loop próprio, NÃO React state)
**Estilo:** Tailwind CSS v3 (APENAS chrome — Topbar, chat sidebar)
**Socket.io:** Client v4 com tipos locais (substituir por @nexus/shared quando existir)

## Regras Críticas

- `imageSmoothingEnabled = false` IMEDIATAMENTE após `canvas.getContext('2d')`
- Canvas CSS: `imageRendering: 'pixelated'` (inline style no elemento)
- AgentStateManager em `useRef`, NUNCA em `useState`
- Estado de agentes (posição, animação) fora do React state — managers mutáveis
- Socket tipado com `Socket<ServerToClientEvents, ClientToServerEvents>`
- Canvas loop DEVE retornar cleanup function; useEffect DEVE retorná-la
- `noUncheckedIndexedAccess: true` — todo acesso a array exige verificação de undefined

## Estrutura do Canvas (Fase 0 implementada)

- **Game loop:** `src/canvas/loop.ts` — startGameLoop retorna cleanup
- **Layers:** drawFloor → drawRooms → drawAgents → drawSpeechBubbles
- **AgentStateManager:** `src/office/state/AgentStateManager.ts` — único dono do estado de agentes
- **Office.tsx:** único componente React que toca Canvas API
- Ver: [project-canvas-structure](project_canvas_structure.md)

## Padrões de Socket.io que Funcionaram

- Criar socket em `useEffect` (não no render), guardar em `useRef`
- `createSocket()` sem URL — usa proxy Vite `/socket.io` em dev
- Fase 0: tipos locais `ServerToClientEvents`/`ClientToServerEvents` em `src/socket/client.ts`

## Gotchas de Pixel Art / Canvas

- `tsc -b` emite `.js` na `src/` quando não há `outDir` — usar apenas `vite build`
- Biome verifica `.js` gerados se estiverem na `src/` — limpar com `find src -name "*.js" -delete`
- `import.meta.env` exige `"types": ["vite/client"]` no tsconfig

## Componentes React Reutilizáveis

- `Topbar` — props: `connected`, `lastPong`, `onPing`
- `Office` — prop: `onMention(agentId)` — encapsula todo o canvas
- `AgentPopover` — props: `agent`, `agentX`, `agentY`, `onClose`, `onMention`
- `useSocket()` — retorna `{ socket, connected, lastPong }`

## Performance

Budget: <16ms por frame (update + draw) para 60fps
Fase 0 (apenas fillRect): custo negligenciável, bem abaixo do budget com 7 agentes
Aviso de frame lento configurado em >12ms (apenas dev)

## Feedback e Lições

- [tsconfig/Vite coreto](feedback_tsconfig_vite.md) — não usar tsc -b no build Vite
- [Biome organizeImports](feedback_biome_organizeimports.md) — usar --fix para auto-corrigir
