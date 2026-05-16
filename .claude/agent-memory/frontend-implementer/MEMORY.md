# Frontend Implementer — Memória (Nexus)

## Stack e Build

**Workspace:** `frontend/`
**Build:** `cd frontend && npm run build`
**TypeScript:** `cd frontend && npx tsc --noEmit`
**Framework:** React + Vite + TypeScript strict
**Renderização:** Canvas API (game loop próprio, NÃO React state)
**Estilo:** Tailwind CSS (só para chrome/UI lateral)
**Socket.io:** Client para comunicação com backend

## Regras Críticas

- `imageSmoothingEnabled = false` SEMPRE que houver sprites pixel art
- Canvas CSS: `image-rendering: pixelated`
- Estado de agentes (posição, animação) fora do React state — usa managers mutáveis
- Tipos de eventos importados de `../../shared/` — NUNCA redefinidos no frontend
- Socket tipado com `Socket<ServerToClientEvents, ClientToServerEvents>`
- Canvas loop retorna cleanup function (evita memory leak no useEffect)

## Estrutura do Canvas (quando criada)

(Preencher após Fase 0/1)
- Game loop: requestAnimationFrame com delta time
- Managers: AgentStateManager, SpeechBubbleManager, etc.
- Layers: background, furniture, agents, bubbles, UI overlay

## Padrões de Socket.io que Funcionaram

(Preencher após implementação)

## Gotchas de Pixel Art

(Preencher após implementação)

## Componentes React Reutilizáveis

(Preencher após implementação)

## Performance

Budget: <16ms por frame (update + draw) para 60fps com 8 agentes
(Preencher com medições reais após implementação)
