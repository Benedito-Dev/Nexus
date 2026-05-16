# PLANO DETALHADO - Task 1: Frontend — Fundação (Fase 0)

**Criado por:** Strategist Agent
**Data:** 2026-05-16
**Módulo:** frontend
**Fase do Roadmap:** 0
**Estimativa Total:** 4-6h (com buffer)
**Prioridade:** MUST

---

## 1. Análise

### Contexto

Fase 0 do Nexus: estruturar o workspace `frontend/` do zero para suportar a
Fase 1 (escritório animado). A pasta existe mas está vazia. O critério de
pronto da fase é simples: canvas vazio renderiza, Socket.io conecta no
backend e troca ping/pong.

Existe um protótipo de design em `Nexus Desing/` — JSX sem TypeScript, sem
Vite, sem build, rodando direto no browser via CDN. Ele é a referência visual e
de comportamento, não ponto de partida de código. Arquitetura de implementação
muda substancialmente ao migrar para o stack definido.

### Estado Atual

- `frontend/` — vazio, sem `package.json`
- `shared/` — vazio, sem `package.json`
- `backend/` — vazio, sem `package.json`
- `pnpm-workspace.yaml` — lista os três workspaces
- `package.json` raiz — scripts de workspace configurados

### Descoberta crítica: o protótipo NÃO usa Canvas API

Ao examinar `Nexus Desing/nexus-office.jsx` e `nexus-sprite.jsx`, fica claro
que o protótipo renderiza o escritório inteiro com **divs absolutamente
posicionadas**, não com Canvas API. Os sprites são gerados via `box-shadow` CSS
(pixel art sem nenhuma imagem). A "câmera" é um container com `overflow: hidden`
e scroll-snap. O CSS em `nexus.css` controla tudo.

Isso muda radicalmente a decisão sobre motor gráfico.

### Impacto no Protocolo

Fase 0 não cria eventos reais — só prepara a infraestrutura de tipos em
`shared/`. O Socket.io vai trocar apenas `ping`/`pong` por enquanto. O schema
completo de eventos será definido no plano do `shared/` (task separada).

---

## 2. Abordagem Escolhida

### Decisão sobre Motor Gráfico: DOM com CSS, sem Canvas, sem PixiJS

**Veredicto: usar a abordagem do protótipo — DOM + CSS + box-shadow —
em vez de Canvas API puro ou qualquer motor gráfico.**

Esta é a decisão mais importante do plano e merece justificativa detalhada.

#### Por que DOM + CSS vence Canvas API puro para o Nexus

O Nexus não é um jogo. É uma UI que parece um jogo. A diferença importa:

1. **Os sprites já existem como box-shadow.** O protótipo tem um gerador
   completo (`nexus-sprite.jsx`) que cria personagens pixel art de 12×18
   pixels via CSS `box-shadow`, com cache de paleta e variante sitting/walking.
   Reescrever isso em Canvas não adiciona nada — só adiciona código e surface
   de bug.

2. **O escritório inteiro é DOM.** Salas, móveis, mesas, plantas, tapetes —
   tudo são divs com classes CSS. O layout é uma grade de tiles (TILE = 36px),
   com posicionamento absoluto. Isso é mais simples de manter que comandos
   Canvas equivalentes.

3. **Câmera onisciente fixa elimina a principal vantagem do Canvas.** Canvas
   brilha em câmeras com scroll, transformações de matriz, culling de objetos
   fora do viewport. Com câmera fixa em 32×18 tiles (~1152×648px), nenhuma
   dessas vantagens se aplica. O escritório inteiro cabe na tela.

4. **Animações com CSS são gratuitas.** Transições de movimento (agente indo de
   mesa A para mesa B) são `transition: left top 600ms ease`. Animações de
   estado (idle, thinking, working) são `@keyframes` e atributos `data-state`.
   Em Canvas, cada frame precisaria de `requestAnimationFrame` + `clearRect` +
   `drawImage` — todo esse código para fazer o mesmo que o browser já faz de
   graça.

5. **Acessibilidade real.** DOM tem `role`, `aria-label`, foco por teclado.
   Canvas é um bitmap opaco — qualquer acessibilidade teria que ser simulada.
   O protótipo já tem `role="button"` e `aria-label` nos sprites.

6. **DevTools funcionam.** Inspecionar um sprite no DOM mostra a div. Inspecionar
   um sprite em Canvas mostra um retângulo cinza. Em 6 meses de desenvolvimento,
   isso importa muito.

#### Por que não PixiJS

PixiJS resolve dores reais de Canvas (batching, sprites sheets, WebGL acelerado).
Mas o DOM + CSS já resolve todas essas dores de outra forma — e com menos
dependência. PixiJS seria a escolha certa se o Nexus tivesse:
- Câmera com scroll e zoom
- Centenas de entidades se movendo simultaneamente
- Efeitos de partícula ou shaders
- Sprites sheet com animação frame-a-frame

Nenhum desses cenários existe no Nexus. Com 7 agentes, câmera fixa e animações
de estado simples, PixiJS seria um canhão pra matar mosquito.

#### Por que não Phaser ou Excalibur

Phaser: 4MB de bundle, sistema de física, câmera, tilemaps — tudo que o Nexus
não precisa. Um framework de game engine completo para uma UI com 7 personagens
sentados em mesas é absurdo.

Excalibur: mais leve, TypeScript nativo, mas ainda pressupõe game loop,
câmera, scene management — overhead arquitetural sem contrapartida.

#### A única ressalva: performance dos sprites

A técnica de `box-shadow` com centenas de valores gera um shadow list longo.
O protótipo já mitiga isso com `_shadowCache` (memoização por paleta). Com
7 agentes, são 14 variantes de shadow no máximo (sitting + walking × 7
paletas) — totalmente gerenciável.

Se um dia surgir problema de performance real (medido), a migração de sprites
para Canvas isolada (só o elemento do personagem, não o escritório todo) é
cirúrgica e não exige refatoração da arquitetura.

#### Implicação na regra de `imageSmoothingEnabled`

A regra `imageSmoothingEnabled = false` nos padrões do projeto foi escrita
pressupondo Canvas API para sprites. Com DOM + CSS, a equivalente é:

```css
image-rendering: pixelated;
```

aplicado ao container do escritório. Já está no protótipo.

Se no futuro uma imagem externa de sprite sheet for usada em um `<img>` ou
`<canvas>` interno, aplica-se `image-rendering: pixelated` no elemento.

### Solução

Estruturar `frontend/` como workspace React + Vite + TypeScript estrito +
Tailwind, usando a abordagem DOM + CSS do protótipo para o escritório, com:

- Componentes React para o escritório (migração limpa do JSX do protótipo)
- State manager separado do React state para posições e estados de agentes
  (mesmo princípio do padrão documentado — só a implementação muda de Canvas
  para refs de DOM)
- Socket.io client tipado com eventos de `shared/`
- Tailwind apenas para o chrome (chat lateral, topbar, modais)
- CSS modules ou CSS puro para o escritório (que tem lógica visual muito
  específica com data-attributes e variáveis CSS)

### Justificativa

Respeita todos os princípios inegociáveis:
- Protocolo de eventos via Socket.io — igual, independente da abordagem visual
- Estado de agentes fora do React state — implementado com refs + manager
- `shared/` como fonte de verdade — igual
- Frontend não sabe se agente é fake ou real — igual

E adiciona vantagens práticas: menos código, menos dependências, animações
CSS gratuitas, DevTools funcionam, acessibilidade real.

### Alternativas Consideradas

**Alternativa A: Canvas API puro (plano original)**
- Pros: controle total sobre renderização, `imageSmoothingEnabled = false` nativo, budget de performance previsível
- Contras: reescrever do zero o que o protótipo já faz em DOM; animações de movimento e estado exigem game loop (requestAnimationFrame + delta time); sem DevTools para inspecionar sprites; sem acessibilidade nativa; ~3x mais código para o mesmo resultado visual
- Veredicto: descartado. O protótipo demonstrou que DOM + CSS resolve o problema com muito menos código. Canvas API seria escolha correta para um Nexus com câmera scrollável ou centenas de entidades — nenhum dos dois existe aqui.

**Alternativa B: PixiJS**
- Pros: WebGL acelerado, sprites sheets nativas, API de alto nível para animações, excelente para pixel art em escala
- Contras: dependência de 500KB+; pressupõe paradigma de game (scene, stage, ticker) que não casa com React; animações de estado simples (idle/thinking/working) são mais verbosas em PixiJS que em CSS data-attributes; nenhum dos problemas que PixiJS resolve (câmera, batching, WebGL) existe no Nexus
- Veredicto: descartado. PixiJS seria correto se o Nexus tivesse scroll de câmera ou dezenas de sprites animados por frame. Com câmera fixa e 7 agentes, é overengineering.

**Alternativa C: DOM + CSS (escolhida)**
- Pros: protótipo já validado, animações CSS gratuitas, DevTools funcionam, zero dependências extras, acessibilidade, menos código
- Contras: sem aceleração WebGL (não importa com câmera fixa); box-shadow longo por sprite (mitigado com cache)
- Veredicto: escolhida.

---

## 3. Estrutura Técnica

### Estrutura de Arquivos

```
frontend/
├── package.json
├── tsconfig.json
├── vite.config.ts
├── tailwind.config.ts
├── postcss.config.js
├── index.html
└── src/
    ├── main.tsx                      # entry point, monta React no #root
    ├── App.tsx                       # layout raiz: topbar + office + chat
    │
    ├── office/                       # escritório DOM (não Tailwind)
    │   ├── Office.tsx                # componente raiz do escritório
    │   ├── AgentSprite.tsx           # sprite CSS box-shadow de um agente
    │   ├── AgentPopover.tsx          # popover ao clicar no agente
    │   ├── DeskStation.tsx           # mesa + monitor + teclado de um agente
    │   ├── Room.tsx                  # zona especial (notion, github, meeting)
    │   ├── Furniture.tsx             # móveis estáticos decorativos
    │   ├── MeetingTable.tsx          # mesa de reunião + cadeiras
    │   ├── office.css                # estilos do escritório (data-attrs, vars CSS, paletas)
    │   │
    │   ├── state/
    │   │   ├── AgentStateManager.ts  # estado mutável de posição e animação (fora do React)
    │   │   └── types.ts              # AgentRenderState, SpeechBubble, etc.
    │   │
    │   └── data/
    │       ├── agents.ts             # definições dos 7 agentes (posição home, desk, paleta)
    │       └── office-layout.ts      # OFFICE: cols, rows, rooms
    │
    ├── chat/                         # chrome lateral (Tailwind)
    │   ├── ChatPanel.tsx             # painel de chat completo
    │   ├── ChatMessage.tsx           # mensagem individual (user / agent / sys)
    │   └── ChatInput.tsx             # input com @mention support
    │
    ├── layout/
    │   ├── Topbar.tsx                # barra superior (projeto, status ws)
    │   └── CanvasArea.tsx            # wrapper do escritório com overflow hidden
    │
    ├── socket/
    │   ├── client.ts                 # createSocket(), NexusSocket type
    │   └── hooks.ts                  # useSocket() hook
    │
    └── shared-types.ts               # re-export de tipos de @nexus/shared
```

### Sobre `office.css` vs Tailwind

O escritório tem lógica visual muito específica: `data-state="thinking"`,
`data-palette="moss"`, variáveis CSS para tile size, pseudo-elementos para
sombras e bordas pixel. Tentar fazer isso com Tailwind seria classes
utilitárias monstruosas. A solução é `office.css` como CSS puro (ou módulo CSS)
para o escritório, e Tailwind para tudo fora dele (topbar, chat, modais,
popovers).

### Eventos WebSocket (Fase 0 — mínimo)

Fase 0 define apenas o ping/pong para validar a conexão. O schema completo
de eventos (`agent.move`, `agent.thinking`, etc.) é definido no plano do
`shared/`. O frontend precisa apenas ser configurado para importar de lá.

```
ping — {} — client→server
pong — {} — server→client
```

### Dependências exatas

**`frontend/package.json`:**

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

Nota: não instalar `pixi.js`, `phaser`, `excalibur`. Não instalar `framer-motion`
(animações são CSS puro). Não instalar `@types/socket.io-client` (v4 já
inclui tipos).

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

`noUncheckedIndexedAccess: true` é deliberado — em código de UI com arrays
de agentes e maps de estado, acesso por índice sem verificação é fonte de
bugs silenciosos.

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

O proxy de `/socket.io` é crítico para Fase 0: permite rodar `vite dev` e
o backend em portas diferentes sem CORS. Em produção, o frontend é servido
pelo mesmo domínio do backend ou via CDN — o proxy não entra em produção.

**`tailwind.config.ts`:**

```typescript
import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        // Paleta do chrome — dark + sóbria (não cyberpunk neon)
        surface: {
          DEFAULT: '#1a1f2e',
          raised: '#222840',
          overlay: '#2a3050',
        },
        accent: {
          DEFAULT: 'oklch(0.78 0.10 220)',  // Rafael blue como cor de destaque base
        },
        border: '#2e3650',
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

**`postcss.config.js`:**

```javascript
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
```

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

## 4. Plano de Implementação (Fases)

### Fase 1: Scaffold do workspace (30-45min)

- [ ] 1.1 Criar `frontend/package.json` com as dependências listadas acima
- [ ] 1.2 Criar `frontend/tsconfig.json` e `frontend/tsconfig.node.json`
- [ ] 1.3 Criar `frontend/vite.config.ts`
- [ ] 1.4 Criar `frontend/tailwind.config.ts` e `frontend/postcss.config.js`
- [ ] 1.5 Criar `frontend/index.html`
- [ ] 1.6 Rodar `pnpm install` na raiz do workspace
- [ ] 1.7 Verificar que `pnpm run dev` no frontend abre sem erro (mesmo sem src/ ainda)

### Fase 2: Entry point e layout base (30min)

- [ ] 2.1 Criar `frontend/src/main.tsx` — monta `<App />` no `#root`
- [ ] 2.2 Criar `frontend/src/App.tsx` — estrutura placeholder: topbar + área central + chat
- [ ] 2.3 Criar `frontend/src/layout/Topbar.tsx` — barra superior com nome do projeto e status WS
- [ ] 2.4 Criar `frontend/src/layout/CanvasArea.tsx` — wrapper com overflow:hidden para o escritório

A App.tsx de Fase 0 pode ser simples:

```tsx
export function App() {
  return (
    <div className="flex flex-col h-screen bg-surface text-gray-100">
      <Topbar />
      <div className="flex flex-1 overflow-hidden">
        <CanvasArea>
          {/* escritório vazio — placeholder */}
          <div className="w-full h-full flex items-center justify-center text-gray-500 text-sm">
            escritório carregando...
          </div>
        </CanvasArea>
        <aside className="w-80 bg-surface-raised border-l border-border">
          {/* chat — placeholder */}
        </aside>
      </div>
    </div>
  );
}
```

### Fase 3: Socket.io client (45min)

- [ ] 3.1 Criar `frontend/src/socket/client.ts` — `createSocket()` com tipagem de ServerToClientEvents / ClientToServerEvents
- [ ] 3.2 Criar `frontend/src/socket/hooks.ts` — `useSocket(url)` retorna `{ socket, connected }`
- [ ] 3.3 Criar `frontend/src/shared-types.ts` — re-export de `@nexus/shared` (arquivo vazio com TODO enquanto shared/ não existe)
- [ ] 3.4 Integrar `useSocket` no `App.tsx`, exibir status de conexão na Topbar
- [ ] 3.5 Testar ping/pong: ao conectar, enviar `ping`, exibir quando receber `pong`

O socket client de Fase 0 pode ser simples — sem os tipos completos ainda:

```typescript
// src/socket/client.ts
import { io, type Socket } from 'socket.io-client';

// Fase 0: tipos mínimos para ping/pong
// Quando shared/ estiver pronto, importar daqui:
// import type { ServerToClientEvents, ClientToServerEvents } from '@nexus/shared';

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

Quando `shared/` for criado (plano separado), esse arquivo é atualizado para
importar os tipos de lá — mudança cirúrgica de 2 linhas.

### Fase 4: Dados e state manager de agentes (45min)

- [ ] 4.1 Criar `frontend/src/office/data/office-layout.ts` — `OFFICE` (cols, rows, rooms)
- [ ] 4.2 Criar `frontend/src/office/data/agents.ts` — `AGENTS[]` com os 7 agentes (posição, paleta, mesa)
- [ ] 4.3 Criar `frontend/src/office/state/types.ts` — `AgentRenderState`, `AgentState`, `SpeechBubble`
- [ ] 4.4 Criar `frontend/src/office/state/AgentStateManager.ts` — gerencia estado mutável (posições, estados, speech bubbles) **fora do React**

O AgentStateManager é o substituto do Canvas state manager descrito nos
padrões. Em vez de coordenar `requestAnimationFrame`, coordena transições de
classe CSS e posições absolutas via refs de DOM. A lógica é equivalente —
estado mutável separado, React só para o que a UI lateral precisa.

```typescript
// Estrutura do AgentStateManager
export class AgentStateManager {
  private states = new Map<string, AgentRenderState>();

  // chamado quando evento socket chega
  setAgentState(id: string, state: AgentState): void
  setAgentPosition(id: string, x: number, y: number): void
  setSpeechBubble(id: string, text: string, durationMs: number): void

  // chamado em intervalo leve (não RAF — não há draw loop)
  tick(): void  // limpa speech bubbles expiradas

  getState(id: string): AgentRenderState | undefined
  getAll(): AgentRenderState[]
}
```

### Fase 5: Componentes do escritório (60-90min)

**Nota importante:** nesta fase (Fase 0 do roadmap), o escritório precisa
existir como estrutura básica para validar o setup, não como implementação
completa. A implementação completa dos sprites, animações e interações é
Fase 1. Aqui, entregamos a estrutura de componentes com stubs funcionais.

- [ ] 5.1 Criar `frontend/src/office/office.css` — variáveis CSS base (--tile, --office-w, --office-h, paletas de carpete)
- [ ] 5.2 Criar `frontend/src/office/Office.tsx` — container do escritório, monta rooms e desks (sem sprites ainda)
- [ ] 5.3 Criar `frontend/src/office/Room.tsx` — zona colorida com label
- [ ] 5.4 Criar `frontend/src/office/DeskStation.tsx` — mesa + monitor + acessórios

Sprites e popover ficam para a Fase 1 do roadmap. Na Fase 0, o escritório
mostra o layout de tiles, salas e mesas — suficiente para validar que a
estrutura funciona.

### Fase 6: Lint, typecheck, build (30min)

- [ ] 6.1 Criar `frontend/biome.json` com configuração padrão
- [ ] 6.2 Rodar `pnpm typecheck` — zero erros TypeScript
- [ ] 6.3 Rodar `pnpm lint` — zero avisos
- [ ] 6.4 Rodar `pnpm build` — build de produção funciona

---

## 5. Estimativa de Tempo

| Fase | Otimista | Realista | Pessimista |
|------|----------|----------|------------|
| 1. Scaffold | 25min | 40min | 60min |
| 2. Entry + Layout | 20min | 30min | 45min |
| 3. Socket.io | 30min | 45min | 70min |
| 4. Dados + StateManager | 30min | 45min | 70min |
| 5. Componentes escritório | 45min | 75min | 110min |
| 6. Lint + typecheck + build | 20min | 30min | 50min |
| **Total** | **2h50min** | **4h25min** | **6h45min** |

Buffer 20%: **~5h30min** para estimativa de compromisso.

---

## 6. Riscos e Mitigações

| Risco | Prob | Impacto | Mitigação |
|-------|------|---------|-----------|
| `@nexus/shared` não resolve em Vite | M | M | Configurar alias em `vite.config.ts` + `tsconfig.json` `paths` — já incluso no plano. Fallback: tipos locais temporários em `shared-types.ts` |
| Conflito de versão React 19 com @types | B | M | React 19 é estável; `@types/react@^19` inclui suporte. Se quebrar, pinnar em 18 temporariamente |
| CSS do escritório vazar para Tailwind | M | B | `office.css` é importado apenas em `Office.tsx`. Tailwind opera no `index.css` global. Separação por arquivo já previne |
| `noUncheckedIndexedAccess` causando erros em código herdado do protótipo | A | B | O protótipo é JSX sem TypeScript — migração exige tipagem explícita de qualquer forma. O flag força essa tipagem correta |
| Proxy Vite não funcionar com Socket.io | B | A | Configuração de proxy websocket testada e documentada nos padrões do projeto. Fallback: CORS no backend para dev |

---

## 7. Critérios de Sucesso (Fase 0)

- [ ] `pnpm run dev` no `frontend/` abre no browser sem erros no console
- [ ] Página renderiza layout básico: topbar + área do escritório + sidebar de chat (pode ser placeholder)
- [ ] Socket.io conecta no backend e exibe status "Connected" na topbar
- [ ] Ping/pong funciona: botão na topbar envia `ping`, backend responde `pong`, UI confirma
- [ ] `pnpm run typecheck` — zero erros TypeScript
- [ ] `pnpm run build` — build de produção sem erros
- [ ] Zero `any` no código produzido (exceto comentado com justificativa)
- [ ] Estrutura de pastas corresponde ao mapa acima (facilita onboarding do Implementer de Fase 1)

---

## 8. Handoff para o Implementer

**Por onde começar:** Fase 1 do plano — scaffold do `package.json` e configs.
Não pule para código de componentes sem o TypeScript compilando limpo.

**Arquivos que o Implementer deve ler primeiro:**
- `C:\Users\Benedito\Documents\Visual Studio Code\Nexus\.claude\rules\nexus-frontend-patterns.md` — padrões de Socket.io e state manager
- `C:\Users\Benedito\Documents\Visual Studio Code\Nexus\Nexus Desing\nexus-sprite.jsx` — entender como os sprites são gerados (box-shadow) antes de implementar `AgentSprite.tsx` na Fase 1
- `C:\Users\Benedito\Documents\Visual Studio Code\Nexus\Nexus Desing\nexus-data.jsx` — dados dos 7 agentes (posição home, desk, paleta) para `agents.ts`
- `C:\Users\Benedito\Documents\Visual Studio Code\Nexus\Nexus Desing\nexus-office.jsx` — estrutura do escritório DOM para `Office.tsx`

**Pontos de atenção:**

1. **Protótipo como referência, não como código.** Os arquivos em `Nexus Desing/`
   são JSX sem TypeScript, sem módulos ES, rodando em browser via CDN. Não
   copiar e colar — migrar com tipagem estrita.

2. **`AgentStateManager` é state fora do React.** Seguir o padrão documentado
   em `nexus-frontend-patterns.md` seção 3. A motivação é a mesma mesmo sem
   Canvas: evitar re-render de 60fps de posições e estados de animação.

3. **Tailwind apenas no chrome.** `office.css` é CSS puro com variáveis e
   data-attributes. Não tentar estilizar elementos do escritório com classes
   Tailwind.

4. **`shared/` pode não existir ainda.** O arquivo `src/shared-types.ts`
   tem tipos locais temporários para Fase 0. Quando o plano do `shared/` for
   executado, esse arquivo é atualizado para importar de `@nexus/shared`.
   Não bloquear a Fase 0 esperando o `shared/` estar completo.

5. **Fase 0 não precisa de sprites.** O escritório de Fase 0 mostra salas e
   mesas como placeholders. Sprites, animações e popover são Fase 1 do roadmap.
   Não implementar antecipado.
