# PLANO DETALHADO - Task 2: Frontend Canvas — Fundação (Fase 0)

**Criado por:** Strategist Agent
**Data:** 2026-05-16
**Módulo:** frontend
**Fase do Roadmap:** 0
**Estimativa Total:** 5-7h (com buffer)
**Prioridade:** MUST

---

## 1. Análise

### Contexto

Plano substituto ao `plan-frontend-fundacao-fase0-task1.md`, que propôs DOM + CSS
como motor de renderização do escritório. Essa proposta foi rejeitada: a stack
definida em `nexus-contexto.md` seção 8.1 especifica **Canvas API** para
renderização do escritório. O documento é lei — o plano obedece.

Objetivo: estruturar `frontend/` do zero para a Fase 0 do roadmap, com Canvas
API como motor do escritório, respeitando todos os princípios arquiteturais do
projeto.

Critério de pronto da Fase 0 (conforme roadmap):
- `pnpm run dev` abre uma página com Canvas funcionando
- Canvas renderiza background simples (piso do escritório)
- Socket.io conecta no backend e troca ping/pong
- Tailwind configurado
- Linter e formatter configurados

### Estado Atual

- `frontend/` — vazio, sem `package.json`
- `shared/` — vazio, sem `package.json`
- `backend/` — tem estrutura básica (definida em plano separado)
- Protótipo em `Nexus Desing/` — referência visual e de UX, NÃO de implementação

### Referência Visual (protótipo `Nexus Desing/`)

O protótipo usa DOM + CSS. Ele é útil para:
- Paletas de cores dos 7 agentes (`nexus-data.jsx`)
- Layout do escritório: 32 cols × 18 rows, TILE = 36px (1152×648px total)
- Posições home e desk de cada agente (em tiles)
- Salas especiais: notion (x:0, y:0, w:7, h:5), github (x:25, y:0, w:7, h:5), meeting (x:10, y:7, w:12, h:6)
- Template dos sprites: 12×18 pixels com chars H/S/T/A/P/B/. (nexus-sprite.jsx)
- Animações de estado: idle (bob), thinking (aura pulsante), working (typing shimmer), moving (walk)

O protótipo NÃO é referência de como implementar — a implementação usa Canvas API.

### Impacto no Protocolo

Fase 0 não cria eventos WebSocket reais além de ping/pong. O schema completo de
eventos (`agent.move`, `agent.thinking`, `agent.speak`, etc.) será definido no
plano do `shared/`. O frontend importará de `@nexus/shared` quando existir;
por ora, tipos locais temporários na Fase 0.

---

## 2. Abordagem Escolhida

### Solução

Canvas API puro (nativo do browser, zero dependências) como motor de renderização
do escritório. React + Tailwind para o chrome. Socket.io client tipado.
AgentStateManager fora do React state, com game loop requestAnimationFrame.

### Arquitetura Canvas no Nexus

O escritório é desenhado frame a frame:
- `requestAnimationFrame` chama `loop(timestamp)` a cada frame
- `update(delta)` atualiza posições e animações no `AgentStateManager`
- `draw(ctx)` renderiza tudo no canvas: piso, salas, móveis, agentes, speech bubbles
- React não controla nada dentro do canvas — só o que está fora (chat, topbar)

Sprites pixel art são desenhados via `ctx.fillRect()` célula por célula, a partir
de templates de string (equivalente ao box-shadow do protótipo, mas em Canvas).
`imageSmoothingEnabled = false` é obrigatório em todo ctx que renderiza sprites.

### Decisão sobre sprites

O template de sprite do protótipo (`SPRITE_TEMPLATE` em nexus-sprite.jsx) é uma
matriz de strings com chars H/S/T/A/P/B/.  O mesmo template pode ser reutilizado
para Canvas: iterar a matriz e chamar `ctx.fillRect(x*PX, y*PX, PX, PX)` para
cada pixel não-transparente. Cache de paleta equivalente ao do protótipo
(memoização por key de paleta).

Isso mantém os sprites pixel art idênticos ao protótipo visualmente, com a
implementação correta em Canvas.

### Justificativa

- Respeita a stack definida em `nexus-contexto.md` seção 8.1 (lei do projeto)
- Canvas API é nativo — zero dependências adicionais
- `imageSmoothingEnabled = false` é nativo do Canvas — pixel art sem blur garantido
- Game loop com delta time é o padrão correto para animações temporalmente
  consistentes (60fps independente de frame rate do monitor)
- AgentStateManager fora do React elimina re-renders a 60fps — padrão já
  documentado em `nexus-frontend-patterns.md`
- Budget de performance previsível: com 7 agentes e câmera fixa, o draw loop
  roda dentro do budget de <5ms por frame sem otimizações especiais

### Alternativas Consideradas

**Alternativa A: DOM + CSS (plano anterior rejeitado)**
- Pros: protótipo já demonstrado, animações CSS gratuitas, DevTools funcionam
- Contras: contraria a stack definida no documento mestre do projeto; mistura
  paradigmas de renderização; animações de movimento via CSS transition não
  permitem interpolação customizada (curvas, easing arbitrário) que um game loop
  permite; mais difícil medir performance do frame
- Veredicto: rejeitado pelo usuário. A stack é Canvas API e o documento é lei.

**Alternativa B: PixiJS**
- Pros: WebGL acelerado, sprites sheets nativas, API de alto nível
- Contras: dependência de 500KB+; abstrai o Canvas de forma que os padrões
  documentados no projeto (`imageSmoothingEnabled`, game loop manual) não se
  aplicam diretamente; `nexus-contexto.md` seção 10 lista frameworks de
  orquestração como fora do roadmap por abstraírem demais — mesmo raciocínio
  se aplica a frameworks de renderização
- Veredicto: descartado. Canvas API é o especificado. PixiJS não entra.

**Alternativa C: Canvas API puro (escolhida)**
- Pros: nativo do browser, zero dependências, `imageSmoothingEnabled = false`
  nativo, game loop com delta time é padrão correto, performance previsível
- Contras: mais código para o mesmo resultado visual que o protótipo DOM; sem
  DevTools para inspecionar elementos do canvas (usar sobreposição de debug em dev)
- Veredicto: escolhida. Respeita a stack definida. O custo de implementação é
  compensado pelo controle total sobre renderização.

---

## 3. Estrutura Técnica

### Estrutura de Arquivos

```
frontend/
├── package.json
├── tsconfig.json
├── tsconfig.node.json
├── vite.config.ts
├── tailwind.config.ts
├── postcss.config.js
├── biome.json
├── index.html
└── src/
    ├── main.tsx                        # entry point, monta React no #root
    ├── App.tsx                         # layout raiz: topbar + canvas area + chat
    ├── index.css                       # reset global + Tailwind directives
    │
    ├── canvas/                         # motor de renderização Canvas API
    │   ├── loop.ts                     # startGameLoop() — requestAnimationFrame + delta time
    │   ├── draw.ts                     # drawOffice() — orquestra todos os draws do frame
    │   ├── drawFloor.ts                # renderiza o piso (tiles alternados)
    │   ├── drawRooms.ts                # renderiza salas especiais (notion, github, meeting)
    │   ├── drawFurniture.ts            # renderiza mesas, cadeiras, decoração estática
    │   ├── drawAgents.ts               # renderiza sprites dos 7 agentes no canvas
    │   ├── drawSpeechBubbles.ts        # renderiza speech bubbles sobre agentes
    │   ├── sprites.ts                  # buildSprite(), spriteShadow() — pixel art via fillRect
    │   └── constants.ts               # TILE=36, OFFICE_W=1152, OFFICE_H=648, PX=2
    │
    ├── office/                         # componentes React do escritório (wrapper do canvas)
    │   ├── Office.tsx                  # <canvas ref> + useEffect com game loop
    │   ├── AgentPopover.tsx            # popover HTML sobre o canvas (z-index acima)
    │   │
    │   ├── state/
    │   │   ├── AgentStateManager.ts    # estado mutável de posição/animação (FORA do React)
    │   │   └── types.ts               # AgentRenderState, AgentState, SpeechBubble, AnimFrame
    │   │
    │   └── data/
    │       ├── agents.ts              # AGENTS[]: 7 agentes com home, desk, sprite palette
    │       └── office-layout.ts       # OFFICE: cols, rows, rooms (tiles coords)
    │
    ├── chrome/                         # UI lateral e overlay — React + Tailwind
    │   ├── Topbar.tsx                  # barra superior: brand, projeto, status WS, ping
    │   ├── ChatPanel.tsx               # painel de chat completo
    │   ├── ChatMessage.tsx             # mensagem individual (user / agent / sys)
    │   └── ChatInput.tsx              # textarea com suporte a @mention
    │
    └── socket/
        ├── client.ts                  # createSocket(), NexusSocket type
        └── hooks.ts                   # useSocket(url) → { socket, connected }
```

### Responsabilidades por arquivo (detalhe)

**`canvas/loop.ts`** — Única fonte de `requestAnimationFrame`. Retorna cleanup
function para uso no `useEffect` do Office. Recebe funções `update(delta)` e
`draw(ctx)` como callbacks.

**`canvas/sprites.ts`** — Traduz o template de string do protótipo para comandos
Canvas. `buildSprite(template, palette)` retorna uma função `drawAt(ctx, x, y)`
que desenha o sprite no canvas na posição dada. Cache por key de paleta. Dois
templates: standing e sitting (idênticos ao protótipo).

**`canvas/draw.ts`** — `drawOffice(ctx, state)` é o ponto de entrada do frame de
renderização: chama drawFloor, drawRooms, drawFurniture, drawAgents,
drawSpeechBubbles nessa ordem.

**`office/state/AgentStateManager.ts`** — Nunca acoplado ao React state.
Mantém `Map<string, AgentRenderState>`. Atualizado por eventos Socket.io e pelo
`update(delta)` do game loop. React apenas consulta para o popover (selectedAgent).

**`office/Office.tsx`** — O único componente React que toca Canvas API. Cria o
`<canvas>`, obtém o contexto via ref, inicia o game loop no `useEffect`, para o
loop no cleanup. Click handler detecta qual agente foi clicado (hit test por
posição tile). Não há SVG, não há divs sobrepostas sobre o escritório exceto o
AgentPopover.

**`office/AgentPopover.tsx`** — Div posicionada absolutamente sobre o canvas
para o popover de agente. Posição calculada a partir das coordenadas do agente
em tiles → pixels. Z-index acima do canvas. Este é o único elemento DOM
posicionado sobre a área do escritório.

### Eventos WebSocket (Fase 0 — mínimo)

```
ping — {} — client → server
pong — {} — server → client
```

Quando `shared/` for criado (plano separado), `socket/client.ts` será atualizado
para importar os tipos de `@nexus/shared`. Nenhuma outra mudança necessária —
a estrutura já prevê isso.

### Dependências exatas

```json
{
  "name": "@nexus/frontend",
  "private": true,
  "version": "0.0.1",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "typecheck": "tsc --noEmit",
    "lint": "biome check src/",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^19.1.0",
    "react-dom": "^19.1.0",
    "socket.io-client": "^4.8.1"
  },
  "devDependencies": {
    "@biomejs/biome": "^1.9.4",
    "@types/react": "^19.1.4",
    "@types/react-dom": "^19.1.3",
    "@vitejs/plugin-react": "^4.4.1",
    "autoprefixer": "^10.4.20",
    "postcss": "^8.5.3",
    "tailwindcss": "^3.4.17",
    "typescript": "^5.8.3",
    "vite": "^6.3.5"
  }
}
```

Proibido: `pixi.js`, `phaser`, `excalibur`, `three`, `framer-motion`.
Nota: `socket.io-client` v4 inclui tipos — não instalar `@types/socket.io-client`.

### Configurações

**`tsconfig.json`:**
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "jsx": "react-jsx",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "exactOptionalPropertyTypes": true,
    "skipLibCheck": true,
    "baseUrl": ".",
    "paths": {
      "@nexus/shared": ["../shared/src/index.ts"]
    }
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

`noUncheckedIndexedAccess: true` é deliberado — acesso a arrays de agentes e
maps de estado sem verificação é fonte de bugs silenciosos em iterações de render.

**`tsconfig.node.json`:**
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "skipLibCheck": true
  },
  "include": ["vite.config.ts", "tailwind.config.ts", "postcss.config.js"]
}
```

**`vite.config.ts`:**
```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@nexus/shared': '../shared/src/index.ts',
    },
  },
  server: {
    port: 5173,
    proxy: {
      '/socket.io': {
        target: 'http://localhost:3000',
        ws: true,
        changeOrigin: true,
      },
    },
  },
});
```

O proxy de `/socket.io` é crítico: permite rodar frontend (porta 5173) e backend
(porta 3000) em dev sem CORS. Em produção, frontend é servido pelo mesmo domínio
ou CDN — o proxy não entra.

**`tailwind.config.ts`:**
```typescript
import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        surface: {
          DEFAULT: 'oklch(0.16 0.012 250)',
          raised:  'oklch(0.20 0.014 250)',
        },
        border:  'oklch(0.27 0.012 250)',
        accent:  'oklch(0.74 0.11 60)',
      },
      fontFamily: {
        mono: ['JetBrains Mono', 'monospace'],
      },
    },
  },
  plugins: [],
};

export default config;
```

Paleta derivada diretamente das variáveis CSS do protótipo (`nexus.css`).

**`postcss.config.js`:**
```javascript
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
```

**`biome.json`:**
```json
{
  "$schema": "https://biomejs.dev/schemas/1.9.4/schema.json",
  "organizeImports": { "enabled": true },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      "suspicious": { "noExplicitAny": "error" }
    }
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "single",
      "semicolons": "always"
    }
  }
}
```

`noExplicitAny` como erro — reforça a política de zero `any` injustificado.

**`index.html`:**
```html
<!doctype html>
<html lang="pt-BR">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Nexus</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

---

## 4. Arquitetura do Canvas (detalhe)

Esta seção detalha o que deve existir em Fase 0 vs o que é Fase 1. Implementer
não deve antecipar Fase 1.

### Game loop (`canvas/loop.ts`)

```typescript
export function startGameLoop(
  ctx: CanvasRenderingContext2D,
  update: (delta: number) => void,
  draw: (ctx: CanvasRenderingContext2D) => void,
): () => void {
  let lastTime = 0;
  let rafId: number;

  function loop(timestamp: number) {
    const delta = lastTime === 0 ? 16 : timestamp - lastTime;
    lastTime = timestamp;

    ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
    update(delta);
    draw(ctx);

    rafId = requestAnimationFrame(loop);
  }

  rafId = requestAnimationFrame(loop);
  return () => cancelAnimationFrame(rafId);
}
```

Medição de performance em dev (só dev, removido em prod):
```typescript
if (import.meta.env.DEV) {
  const elapsed = performance.now() - start;
  if (elapsed > 12) console.warn(`Frame lento: ${elapsed.toFixed(1)}ms`);
}
```

### AgentStateManager (`office/state/AgentStateManager.ts`)

Estado de agentes NUNCA no React state. A classe é instanciada uma vez e
mantida em `useRef` no componente Office.

```typescript
// tipos em office/state/types.ts
export type AgentState = 'idle' | 'thinking' | 'working' | 'moving' | 'speaking';

export interface AgentRenderState {
  id: string;
  x: number;          // posição atual em pixels (interpolada durante movimento)
  y: number;
  targetX: number;    // destino do movimento
  targetY: number;
  state: AgentState;
  animPhase: number;  // 0..1, avança com delta time
  sitting: boolean;
  speechBubble: SpeechBubble | null;
}

export interface SpeechBubble {
  text: string;
  expiresAt: number;  // Date.now() + duration
}
```

```typescript
// AgentStateManager — interface pública
export class AgentStateManager {
  initialize(agents: AgentDefinition[]): void
  setState(id: string, state: AgentState): void
  moveTo(id: string, x: number, y: number, durationMs: number): void
  showSpeech(id: string, text: string, durationMs: number): void
  update(delta: number): void  // avança animPhase, interpola posição, expira bubbles
  getAll(): AgentRenderState[]
  hitTest(px: number, py: number): string | null  // retorna id do agente clicado
}
```

### Sprites (`canvas/sprites.ts`)

Template idêntico ao do protótipo (mesma string), mas desenhado via Canvas:

```typescript
const SPRITE_TEMPLATE_STANDING = [
  '............', // rows 0-1: vazio
  '............',
  '...HHHHHH...', // row 2: cabelo
  // ... igual ao nexus-sprite.jsx
] as const;

const PX = 2; // tamanho de 1 pixel em pixels de tela

type SpritePalette = {
  skin: string; hair: string; shirt: string;
  pants: string; shoes: string;
};

// Retorna função que desenha o sprite em (x, y) do canvas
// Cache por key de paleta — não recalcula a cada frame
export function buildSprite(
  palette: SpritePalette,
  sitting = false,
): (ctx: CanvasRenderingContext2D, x: number, y: number) => void
```

O cache é essencial: com 7 agentes × 2 variantes (sitting/standing), são 14
funções de draw máximo. Cada função é criada uma vez e reutilizada a cada frame.

### Office.tsx — integração Canvas + React

```typescript
export function Office({ manager }: { manager: AgentStateManager }) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [selectedAgentId, setSelectedAgentId] = useState<string | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d')!;
    ctx.imageSmoothingEnabled = false;  // OBRIGATÓRIO — sem blur em pixel art

    const cleanup = startGameLoop(
      ctx,
      (delta) => manager.update(delta),
      (ctx) => drawOffice(ctx, manager.getAll()),
    );

    return cleanup;
  }, [manager]);

  const handleClick = useCallback((e: React.MouseEvent<HTMLCanvasElement>) => {
    const rect = canvasRef.current!.getBoundingClientRect();
    const px = e.clientX - rect.left;
    const py = e.clientY - rect.top;
    setSelectedAgentId(manager.hitTest(px, py));
  }, [manager]);

  const selectedAgent = selectedAgentId
    ? AGENTS.find(a => a.id === selectedAgentId) ?? null
    : null;

  return (
    <div className="relative">
      <canvas
        ref={canvasRef}
        width={OFFICE_W}
        height={OFFICE_H}
        onClick={handleClick}
        style={{ imageRendering: 'pixelated' }}
      />
      {selectedAgent && (
        <AgentPopover
          agent={selectedAgent}
          onClose={() => setSelectedAgentId(null)}
          onMention={(id) => { /* injetado pelo App */ }}
        />
      )}
    </div>
  );
}
```

`imageSmoothingEnabled = false` no contexto Canvas + `imageRendering: pixelated`
no elemento CSS são complementares: o primeiro garante que drawImage não interpola,
o segundo garante que o browser não interpola ao escalar o canvas via CSS.

### O que NÃO implementar na Fase 0

A Fase 0 entrega a **estrutura** funcionando. Estes itens são Fase 1:
- Sprites pixel art completos dos agentes (Fase 0 pode desenhar placeholder — um
  retângulo colorido na posição do agente, com a cor de chatColor do agente)
- Animações de estado (idle bob, thinking aura, working typing)
- Animações de movimento (interpolação para targetX/targetY)
- AgentPopover completo (Fase 0 pode ter stub sem interação)
- Mobília decorativa detalhada (Fase 0 desenha piso + salas + mesas como
  retângulos coloridos simples)
- Chat com streaming

O escritório de Fase 0 deve parecer um mapa de tiles rudimentar — funcional,
não polido. O polimento é Fase 1.

---

## 5. Plano de Implementação (Fases)

### Fase 1: Scaffold do workspace (30-45min)

- [ ] 1.1 Criar `frontend/package.json` com as dependências listadas
- [ ] 1.2 Criar `frontend/tsconfig.json` e `frontend/tsconfig.node.json`
- [ ] 1.3 Criar `frontend/vite.config.ts`
- [ ] 1.4 Criar `frontend/tailwind.config.ts` e `frontend/postcss.config.js`
- [ ] 1.5 Criar `frontend/biome.json`
- [ ] 1.6 Criar `frontend/index.html`
- [ ] 1.7 Rodar `pnpm install` na raiz
- [ ] 1.8 Verificar que o workspace resolve (pnpm list em frontend/)

### Fase 2: Entry point e layout base (30min)

- [ ] 2.1 Criar `src/index.css` — reset + Tailwind directives (`@tailwind base; @tailwind components; @tailwind utilities;`)
- [ ] 2.2 Criar `src/main.tsx` — monta `<App />` no `#root`, importa index.css
- [ ] 2.3 Criar `src/chrome/Topbar.tsx` — barra superior com brand, status WS placeholder
- [ ] 2.4 Criar `src/App.tsx` — layout: grid `44px 1fr`, topbar + `grid 1fr 380px` (canvas + chat)

App.tsx de Fase 0:
```tsx
export function App() {
  return (
    <div className="flex flex-col h-screen bg-[oklch(0.10_0.008_250)]">
      <Topbar connected={false} onPing={() => {}} />
      <div className="flex flex-1 overflow-hidden">
        <div className="flex-1 relative overflow-hidden bg-[oklch(0.12_0.010_245)]">
          {/* Office Canvas — montado na Fase 3 */}
        </div>
        <aside className="w-80 border-l border-[oklch(0.27_0.012_250)] bg-[oklch(0.16_0.012_250)]">
          {/* Chat — placeholder Fase 0 */}
        </aside>
      </div>
    </div>
  );
}
```

### Fase 3: Canvas mínimo funcionando (45-60min)

- [ ] 3.1 Criar `src/canvas/constants.ts` — TILE, OFFICE_W, OFFICE_H, PX
- [ ] 3.2 Criar `src/canvas/loop.ts` — startGameLoop com delta time e cleanup
- [ ] 3.3 Criar `src/office/state/types.ts` — AgentRenderState, AgentState, SpeechBubble
- [ ] 3.4 Criar `src/office/data/office-layout.ts` — OFFICE (cols, rows, rooms)
- [ ] 3.5 Criar `src/office/data/agents.ts` — AGENTS[] com os 7 agentes
- [ ] 3.6 Criar `src/canvas/drawFloor.ts` — renderiza piso em tiles alternados
- [ ] 3.7 Criar `src/canvas/drawRooms.ts` — renderiza salas como retângulos coloridos com label
- [ ] 3.8 Criar `src/canvas/draw.ts` — drawOffice() orquestra drawFloor + drawRooms
- [ ] 3.9 Criar `src/office/state/AgentStateManager.ts` — stub mínimo (initialize, getAll, update, hitTest)
- [ ] 3.10 Criar `src/office/Office.tsx` — canvas com loop, ctx.imageSmoothingEnabled = false, drawOffice
- [ ] 3.11 Integrar Office no App.tsx
- [ ] 3.12 Verificar: `pnpm run dev` abre página com canvas renderizando piso e salas

Neste ponto, o canvas mostra o mapa de tiles básico: piso de madeira (cores
alternadas), salas Notion/GitHub/Meeting com cores distintas. Sem agentes ainda.

### Fase 4: Agentes placeholder no Canvas (30-45min)

- [ ] 4.1 Criar `src/canvas/drawAgents.ts` — agentes como retângulos 24×36px com a cor chatColor de cada agente, em sua posição home em tiles
- [ ] 4.2 Criar `src/canvas/drawSpeechBubbles.ts` — stub (sem speech bubbles na Fase 0, mas a função deve existir como no-op)
- [ ] 4.3 Completar AgentStateManager: `initialize()` carrega posições dos AGENTS, `getAll()` retorna estados, `hitTest()` detecta clique por bounding box
- [ ] 4.4 Integrar manager no Office.tsx com update/draw
- [ ] 4.5 Criar `src/office/AgentPopover.tsx` — stub: div simples com nome e botão "Falar"
- [ ] 4.6 Verificar: 7 retângulos coloridos nas posições corretas do mapa de tiles

### Fase 5: Socket.io client (45min)

- [ ] 5.1 Criar `src/socket/client.ts` — NexusSocket type, createSocket()
- [ ] 5.2 Criar `src/socket/hooks.ts` — useSocket(url) com connect/disconnect
- [ ] 5.3 Integrar useSocket no App.tsx
- [ ] 5.4 Atualizar Topbar para mostrar status Connected/Disconnected
- [ ] 5.5 Adicionar botão "Ping" na Topbar que emite evento `ping`
- [ ] 5.6 Ouvir evento `pong` e exibir confirmação (log no console + indicador na topbar)
- [ ] 5.7 Testar com backend rodando — ping/pong deve funcionar

```typescript
// src/socket/client.ts — Fase 0
import { io, type Socket } from 'socket.io-client';

// Tipos temporários — substituir por @nexus/shared quando shared/ existir
interface ServerToClientEvents {
  pong: () => void;
}
interface ClientToServerEvents {
  ping: () => void;
}

export type NexusSocket = Socket<ServerToClientEvents, ClientToServerEvents>;

export function createSocket(): NexusSocket {
  return io({ path: '/socket.io' }) as NexusSocket;
}
```

### Fase 6: Lint, typecheck, build (30min)

- [ ] 6.1 Rodar `pnpm typecheck` — zero erros TypeScript
- [ ] 6.2 Rodar `pnpm lint` — zero avisos Biome
- [ ] 6.3 Rodar `pnpm build` — build de produção sem erros
- [ ] 6.4 Verificar zero `any` no código (Biome `noExplicitAny` como erro já cobre isso)

---

## 6. Estimativa de Tempo

| Fase | Otimista | Realista | Pessimista |
|------|----------|----------|------------|
| 1. Scaffold | 25min | 40min | 60min |
| 2. Entry + Layout | 20min | 30min | 45min |
| 3. Canvas mínimo | 40min | 60min | 90min |
| 4. Agentes placeholder | 25min | 40min | 60min |
| 5. Socket.io | 30min | 45min | 70min |
| 6. Lint + typecheck + build | 20min | 30min | 50min |
| **Total** | **2h40min** | **4h05min** | **6h15min** |

Buffer 20%: **~5h** para estimativa de compromisso.

---

## 7. Riscos e Mitigações

| Risco | Prob | Impacto | Mitigação |
|-------|------|---------|-----------|
| `@nexus/shared` não resolve em Vite antes de shared/ existir | A | B | Alias em vite.config.ts aponta para arquivo que não existe — não é problema: client.ts usa tipos locais temporários na Fase 0. Alias só é ativado quando shared/ existir. |
| `ctx.imageSmoothingEnabled = false` esquecido | M | A | Adicionar à checklist de revisão. Biome não detecta, mas o resultado visual é imediato (sprites borrados). |
| Game loop não parar no unmount (memory leak) | M | M | Cleanup function retornada por startGameLoop() DEVE ser retornada pelo useEffect. Lint custom rule não existe — é responsabilidade do Implementer seguir o padrão documentado. |
| Proxy Vite não funcionar com Socket.io ws | B | A | Configuração de proxy WS testada e documentada. Se falhar: habilitar CORS no backend só em dev (`origin: 'http://localhost:5173'`). |
| React 19 com breaking changes não documentadas | B | M | Pinnar em `^19.1.0` (estável). Se quebrar, rebaixar para `^18.3.0` temporariamente — mudança de 1 linha no package.json. |
| Performance do canvas com 7 agentes em dev | B | M | Fase 0 só desenha retângulos — custo negligenciável. Performance real de sprites pixel art é avaliada na Fase 1, com sprites completos. |

---

## 8. Critérios de Sucesso (Fase 0)

- [ ] `pnpm run dev` no `frontend/` abre no browser sem erros no console
- [ ] Canvas renderiza: piso com tiles alternados + salas coloridas (Notion/GitHub/Meeting) + 7 retângulos coloridos nas posições dos agentes
- [ ] `ctx.imageSmoothingEnabled = false` aplicado ao inicializar o canvas
- [ ] `imageRendering: pixelated` aplicado no elemento `<canvas>`
- [ ] Game loop retorna cleanup function e para no unmount do componente
- [ ] AgentStateManager não causa re-render React a 60fps (estado mutável em `useRef`)
- [ ] Socket.io conecta no backend (indicador "Connected" na Topbar)
- [ ] Ping/pong funciona: botão envia `ping`, backend responde `pong`, Topbar confirma
- [ ] `pnpm run typecheck` — zero erros TypeScript
- [ ] `pnpm run build` — build de produção sem erros
- [ ] Zero `any` no código (Biome verifica como erro)
- [ ] Tailwind usado APENAS no chrome (Topbar, chat sidebar) — canvas é CSS inline mínimo

---

## 9. Handoff para o Implementer

**Por onde começar:** Fase 1 do plano — scaffold do package.json e configs.
Não pule para código de componentes sem o TypeScript compilando limpo.

**Ordem crítica:**
1. Scaffold (package.json, tsconfigs, vite.config, biome.json, index.html)
2. `pnpm install` na raiz — verificar que workspace resolve
3. Entry point mínimo (main.tsx, App.tsx stub, index.css)
4. `pnpm run dev` deve abrir antes de qualquer Canvas
5. Canvas loop + drawFloor + Office.tsx
6. Agentes placeholder no canvas
7. Socket.io
8. Typecheck + lint + build

**Arquivos do protótipo para ler ANTES de implementar:**

- `Nexus Desing/nexus-data.jsx` — posições home/desk e paletas dos 7 agentes.
  Esses dados vão para `src/office/data/agents.ts` como TypeScript estrito.
- `Nexus Desing/nexus-sprite.jsx` — template de sprite (strings). Entender a
  estrutura antes de implementar `src/canvas/sprites.ts`. Os templates
  SPRITE_TEMPLATE e SPRITE_TEMPLATE_SITTING são reutilizados literalmente —
  só a renderização muda (Canvas fillRect em vez de box-shadow).
- `Nexus Desing/nexus.css` — variáveis CSS de cor (--floor, --floor-2, --wall,
  --notion-floor, --github-floor, --carpet). Usar essas cores nos draws Canvas.

**Pontos de atenção específicos:**

1. **`ctx.imageSmoothingEnabled = false` é obrigatório** imediatamente após
   `canvas.getContext('2d')`. Não depois. Se esquecido, os sprites ficam borrados
   e o resultado não parece pixel art.

2. **Game loop retorna cleanup function.** O `useEffect` em Office.tsx DEVE
   retornar `cleanup`. Esquecido = loop continua rodando após unmount = memory leak
   crescente. Não há lint para isso — é responsabilidade do Implementer.

3. **AgentStateManager em useRef, não useState.** Instanciar uma vez fora do
   render cycle. Se colocado no useState, React tenta comparar estados e cria
   re-renders desnecessários. O padrão correto está em `nexus-frontend-patterns.md`
   seção 3.

4. **Fase 0 não precisa de sprites completos.** Um retângulo de 24×36px com a
   cor `chatColor` do agente é suficiente. Sprites pixel art completos são Fase 1.
   Não implementar antecipado.

5. **Dados dos agentes vêm do protótipo mas precisam ser TypeScript estrito.**
   `agents.ts` define uma interface `AgentDefinition` com todos os campos
   necessários. `noUncheckedIndexedAccess` está ligado — acessar
   `AGENTS[i]` exige verificação de undefined.

6. **Canvas `width` e `height` são atributos, não CSS.** O canvas deve ter
   `width={OFFICE_W}` e `height={OFFICE_H}` como props do elemento React
   (que viram atributos HTML). Se estilizados via CSS apenas, o canvas fica
   distorcido.

7. **Hit test de agente em clique.** `Office.tsx` calcula posição do clique
   relativa ao canvas (`e.clientX - rect.left`), passa para
   `manager.hitTest(px, py)` que retorna o `id` do agente ou `null`. O
   resultado vai para `setSelectedAgentId` — este é o único state React
   relacionado ao canvas (controla qual popover exibir).
