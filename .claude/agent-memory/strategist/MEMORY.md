# Strategist Agent — Memória (Nexus)

## Projeto

**Nome:** Nexus
**Domínio:** Plataforma visual de orquestração de múltiplos agentes IA
**Stack:** React + Vite + Canvas API (frontend) | Node.js + TypeScript + Fastify + Socket.io (backend) | shared/ (protocolo de eventos TS)
**Monorepo:** pnpm, estrutura flat (frontend/, backend/, shared/)
**Fase atual:** 0 — Fundação (não iniciada)

## Princípios Inegociáveis (nunca violar no planejamento)

1. Agentes fake e reais usam o MESMO protocolo de eventos — frontend nunca sabe qual é qual
2. Schema de eventos vive em `shared/` — mudança = breaking change em ambos os lados
3. Projeto é unidade de contexto isolada (Socket.io rooms)
4. Mesma engine, dois figurinos (personalidade = troca de system prompt, não código)
5. Status real no speech bubble — não teatro

## Caso de Uso Âncora

"Nexus, busca no Notion toda a documentação sobre o projeto X, enriquece com fontes da internet, passa pro Implementer escrever um código base mockado seguindo o Design System do agente Designer, e sobe num repositório GitHub."

Todo plano deve ser medido contra esse fluxo.

## Os 7 Agentes do MVP

Diretor (Marina), Estrategista, Documenter, Arquiteto, Implementer, Reviewer, Designer.
Nota: Estrategista e Arquiteto podem se sobrepor — observar em uso real, considerar fusão.

## Roadmap (6 Fases)

- Fase 0: Fundação (canvas vazio, websocket, protocolo)
- Fase 1: Agentes fake animados ("demo do uau")
- Fase 2: Primeiro agente real (Diretor)
- Fase 3: Time completo real
- Fase 4: Persistência e projetos (Prisma + PostgreSQL)
- Fase 5: Integrações reais (Notion MCP, GitHub MCP)
- Fase 6: Pronto para usuários (auth, BYOK, billing, deploy)

## Decisões Arquiteturais Registradas

### 2026-05-16 — Stack backend: Node.js + TypeScript (não Python)
- Motivo: protocolo de eventos é o coração; em Node+TS vive em pacote único
- Divergência no shared/ = erro de compilação (TypeScript garante)
- Socket.io mais maduro; MCP first-class em TS; uma linguagem só

### 2026-05-16 — Monorepo flat (não apps/ + packages/)
- Motivo: só 3 workspaces — aninhar atrapalha navegação e paths
- Se crescer pra múltiplos apps/packages: reorganizar depois (custo baixo)

### 2026-05-16 — Frontend usa Canvas API (stack definitiva — Task 2)
- `nexus-contexto.md` seção 8.1 especifica Canvas API para o escritório. Documento é lei.
- Task 1 propôs DOM + CSS baseado no protótipo — rejeitado pelo usuário. Task 2 corrige isso.
- Sprites pixel art via `ctx.fillRect()` usando o mesmo template string do protótipo (12×18px, chars H/S/T/A/P/B)
- Game loop: `requestAnimationFrame` + delta time + cleanup function no useEffect
- `ctx.imageSmoothingEnabled = false` OBRIGATÓRIO imediatamente após `getContext('2d')`
- `imageRendering: pixelated` no elemento `<canvas>` via CSS
- AgentStateManager em `useRef` — estado mutável fora do React state, nunca causa re-render a 60fps
- Tailwind APENAS para chrome (Topbar, ChatPanel). Canvas é renderização programática.
- AgentPopover é a única div DOM posicionada sobre o canvas (z-index acima)
- Fase 0: agentes como retângulos coloridos (chatColor). Sprites completos são Fase 1.
- Budget performance: <5ms por frame com 7 agentes (câmera fixa, sem culling necessário)

## Protótipo de Referência Visual

- `Nexus Desing/nexus-data.jsx` — dados dos 7 agentes (nome, posição, paleta, bio), layout do escritório
- `Nexus Desing/nexus-sprite.jsx` — gerador de sprites CSS box-shadow com cache de paleta
- `Nexus Desing/nexus-office.jsx` — componentes DOM do escritório (Room, DeskStation, AgentSprite, Popover)
- `Nexus Desing/nexus-chat.jsx` — chat lateral (referência para ChatPanel)
- `Nexus Desing/nexus-app.jsx` — App raiz com cenas (idle/executing/meeting)
- `Nexus Desing/nexus.css` — estilos completos do protótipo
- ATENÇÃO: protótipo é JSX sem TypeScript, sem módulos ES, sem Vite. Migrar, não copiar.

## Riscos Conhecidos

- Latência LLM matando imersão (3-30s) → streaming + animações
- Custo de 4-6 agentes por tarefa → BYOK + estimativa + cap
- Complexidade do orquestrador → workflow linear primeiro
- box-shadow longo por sprite → mitigado com cache de paleta (já implementado no protótipo)
- Estrategista vs Arquiteto sobrepostos → observar uso real
- Desincronização frontend/backend → monorepo + shared/ + TS estrito

## Patterns de Plan que Funcionam

- Examinar `Nexus Desing/` antes de planejar qualquer feature visual — protótipo tem dados úteis (paletas, posições, templates)
- Fase 0: não implementar sprites/animações completos — agentes como retângulos coloridos, estrutura do canvas funcionando
- Canvas API e game loop: sempre verificar que cleanup function é retornada no useEffect
- `nexus-contexto.md` é lei — se proposta de plano contrariar seção 8.1, o plano está errado
- Task 1 do frontend foi rejeitada por propor DOM + CSS. Task 2 corrige com Canvas API.

## Bounded Contexts

- `shared/` → consumido por frontend E backend (nunca modificar sem atualizar os dois lados)
- `frontend/` → Canvas API (escritório) + React + Tailwind (chrome) + Socket.io client
- `backend/` → Fastify + Socket.io server + agentes + LLM providers
- Fase 4+: Prisma + PostgreSQL entram no backend
