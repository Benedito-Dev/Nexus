# Nexus

Plataforma visual de orquestração de múltiplos agentes IA, com interface
imersiva de escritório 2D em pixel art. O usuário é o **diretor** observando
uma equipe de agentes especializados trabalhar — não alguém digitando prompts.

## Leia antes de qualquer coisa

Toda decisão de arquitetura, escopo ou produto está consolidada em:

- **`docs/nexus-contexto.md`** — visão, arquitetura conceitual, agentes,
  decisões tomadas, escopo negativo, glossário, histórico de decisões.
  **Este é o documento mestre.** Leia inteiro antes de propor mudanças
  estruturais.
- **`docs/nexus-roadmap.md`** — fases do projeto com critérios objetivos
  de pronto. Mostra onde estamos e o que vem a seguir.
- **`docs/eventos.md`** — schema do protocolo de eventos WebSocket
  (nasce na Fase 0; pode ainda não existir).

Se a pergunta for sobre **o que** o Nexus é ou **por que** algo foi decidido,
a resposta está nesses arquivos. Não invente, consulte.

## Caso de uso âncora

Toda decisão técnica deve ser medida contra este fluxo:

> "Nexus, busca no meu Notion toda a documentação sobre o projeto X,
> enriquece com fontes da internet, passa pro Implementer escrever um
> código base mockado seguindo o Design System do agente Designer, e
> sobe num repositório GitHub."

Se uma sugestão atrapalha esse fluxo, ela está errada. Se uma feature
não aparece nele (ou em variações próximas), ela não é MVP.

## Princípios arquiteturais inegociáveis

1. **Agentes fake e reais usam o MESMO protocolo de eventos.** O frontend
   nunca sabe se está conversando com um script ou com uma LLM real. A
   transição é trocar o cérebro, não refazer a casa. Se uma mudança
   quebrar isso, ela está errada — me avise.

2. **Schema dos eventos é fonte única de verdade** e vive em `shared/`.
   Frontend e backend importam dele. Mudança no schema = mudança
   coordenada nos dois lados, no mesmo commit.

3. **Projeto é unidade de contexto isolada.** Nada vaza entre projetos
   sem ação explícita do usuário.

4. **Mesma engine, dois figurinos.** Personalidade vs profissional, fake
   vs real — tudo é configuração (system prompt, flag), nunca código
   duplicado.

5. **Status real, não teatro.** Speech bubbles refletem o que o agente
   está realmente fazendo. Nunca inventar atividade falsa pra parecer
   vivo.

## Stack

- **Frontend:** React + Vite, Canvas API (escritório), Tailwind (chrome),
  WebSocket nativo.
- **Backend:** Python + FastAPI, WebSocket nativo, abstração de provider
  de LLM (Anthropic / Groq / OpenAI), integrações via MCP preferencialmente.
- **Monorepo:** front, back e `shared/` no mesmo repo. Pasta `shared/`
  abriga o schema dos eventos e tipos derivados.

## Estrutura do repo

```
nexus/
├── CLAUDE.md                 # este arquivo
├── docs/                     # documentos mestres do projeto
├── shared/                   # protocolo de eventos (schema + tipos)
├── frontend/                 # React + Vite
└── backend/                  # FastAPI
```

## Postura ao trabalhar neste repo

- **Direto e opinativo.** Quando pedirem opinião, dê opinião com
  justificativa. Sem ficar em cima do muro.
- **Discorde quando achar que está errado**, com argumento técnico.
  Concordância passiva não ajuda.
- **Sem bajulação.** Elogio só quando merecido.
- **Aponte gambiarras e seu custo futuro.** O projeto é maratona, sem
  prazo. Priorize decisões sustentáveis no longo prazo mesmo que custem
  mais agora.
- **Não pule fases do roadmap.** Cada fase tem critério objetivo de
  pronto. Não trabalhe em algo de fase futura sem completar a atual.
- **Antes de propor refatoração grande**, verifique se a decisão já está
  registrada em `docs/nexus-contexto.md`. Não desfaça decisão tomada sem
  argumentar.

## O que NÃO está no caminho crítico

Não sugira trabalho nestas áreas a menos que explicitamente pedido —
elas estão fora do MVP por decisão consciente (ver seção 10 do
`nexus-contexto.md` pra lista completa):

- Mobile / responsivo
- Multiplayer / colaboração
- Editor de código embutido
- Voz / TTS
- Customização visual do escritório
- Marketplace de agentes
- SSO / SAML

## Idioma

Português brasileiro, tom conversacional mas técnico. Termos em inglês
quando forem padrão da área (commit, deploy, repo, WebSocket) sem
traduzir forçado.

## Atualização da documentação

Quando uma decisão nova relevante for tomada, **lembre o usuário** de
atualizar `docs/nexus-contexto.md` ou `docs/nexus-roadmap.md` ao final
da conversa. Não atualize por conta própria sem ele pedir.