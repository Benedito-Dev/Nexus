# Prompt — Prototipação Visual do Nexus

> Use este prompt no Claude.ai (com artifacts) ou no v0.dev para gerar
> o protótipo HTML/CSS/React da interface do Nexus.
> O objetivo é definir o escopo visual antes de implementar o backend.

---

## PROMPT

Preciso que você crie um protótipo visual interativo da interface do **Nexus**, uma plataforma de orquestração de múltiplos agentes IA com escritório 2D em pixel art.

---

### O que é o Nexus

O Nexus é uma plataforma onde o usuário dá uma tarefa de alto nível e **assiste** uma equipe de agentes IA trabalhando: cada agente fica na sua mesa, anda pelo escritório, exibe balões de fala curtos, e o resultado aparece num chat lateral. A experiência é de ser um **diretor observando sua equipe** — não alguém digitando prompts.

**Caso de uso âncora (referência para todas as decisões):**
> "Nexus, busca no meu Notion toda a documentação sobre o projeto X, enriquece com fontes da internet, passa pro Implementer escrever um código base mockado seguindo o Design System do agente Designer, e sobe num repositório GitHub."

---

### Estética visual

- **Pixel art 2D top-down**, estilo Stardew Valley, porém com paleta mais sóbria e dark — "Stardew Valley mais dark"
- **Não é cyberpunk** — sem neon saturado. O dark vem da paleta sóbria (tons de cinza-azulado, verde musgo, madeira escura), não de efeitos de luz
- **Estilo Gather.town / virtual office** mas com mais personalidade visual
- Densidade visual média: detalhes ambientais (plantas, monitores, xícaras de café) sem poluir
- Personagens são sprites pequenos, sem rosto detalhado, mas com personalidade reconhecível no sprite
- **Câmera onisciente** — o usuário não tem avatar no escritório. Visão de cima de tudo

---

### Layout da interface

A interface tem **duas zonas principais**:

**Zona 1 — Canvas do escritório (esquerda/centro, ~75% da tela)**
- Escritório 2D top-down com mesas dos agentes
- Câmera estática ou com pan suave
- Agentes se movem entre mesas e salas
- Speech bubbles curtos sobre as cabeças (máx. 40 chars)
- Salas visíveis: mesas individuais de cada agente, sala de reunião central, salas de integração no canto (Notion, GitHub)

**Zona 2 — Chrome lateral (direita, ~25% da tela)**
- Chat fixo vertical
- Histórico de mensagens dos agentes com streaming (aparece letra por letra)
- Input do usuário na parte inferior
- Status da conexão (online/offline) no topo
- Nome do projeto ativo

---

### Os 7 agentes do MVP

Cada agente tem mesa própria no escritório. Nomes e papéis:

| Agente | Nome | Papel |
|---|---|---|
| Diretor | Marina | Recebe tarefa, coordena os demais, sintetiza resultado |
| Estrategista | Rafael | Planeja, pesquisa, faz análises |
| Documenter | Ana | Pesquisa documental, busca em Notion/web |
| Arquiteto | Bruno | Planeja código, stack, decisões técnicas |
| Implementer | Lucas | Escreve código |
| Reviewer | Carla | Valida código e resultados |
| Designer | Diego | Design system, UI/UX |

**Estados visuais de cada agente:**
- `idle` — sentado na mesa, animação suave (piscar, mover levemente)
- `thinking` — indicador visual de processamento (pontinhos? aura suave?)
- `working` — animação de digitação / movendo objetos na mesa
- `moving` — andando pelo escritório em direção a outra mesa ou sala
- `speaking` — speech bubble ativo acima da cabeça

---

### Interações com agentes

**Clicar num agente** abre um popover leve (não modal, não bloqueia a tela) com:
- Nome e papel do agente
- Status atual: "Analisando a documentação do projeto X..."
- Botão "Falar com ele" → foca o input do chat e adiciona `@Marina` no início

**Popover fecha** ao clicar fora ou ao apertar Escape.

---

### Chat lateral — comportamento

- Mensagens identificadas por agente (cor ou avatar pequeno)
- Streaming token-a-token (texto aparece progressivamente)
- Suporte a `@NomeAgente` no input para direcionar mensagens
- Área de mensagens com scroll automático pro fim
- Input com placeholder: "Descreva uma tarefa ou fale com um agente..."
- Botão de enviar ou Enter para submeter

**Tipos de mensagem no chat:**
- Mensagem do usuário (alinhada à direita)
- Resposta do agente (alinhada à esquerda, com identificação)
- Status do sistema: "Tarefa iniciada", "Diretor está coordenando..."

---

### Salas especiais

No canto do escritório, existem **salas de integração** — não são agentes, são destinos:
- **Sala Notion** — ícone de livro/base de dados. Agente "anda até lá" pra buscar info
- **Sala GitHub** — ícone de repositório. Agente "anda até lá" pra commitar/criar PR
- **Sala de Reunião** — mesa central maior. Vários agentes se reúnem aqui pra alinhar

Visualmente, salas têm fundo ligeiramente diferente (borda ou cor de piso diferente) pra destacar.

---

### O que o protótipo deve mostrar

**Tela 1 — Estado idle (escritório em repouso)**
- Todos os 7 agentes nas suas mesas, animações idle
- Chat lateral vazio com input visível
- Sem tarefa ativa

**Tela 2 — Tarefa em execução**
- Marina (Diretor) em estado `thinking` com speech bubble "Analisando a tarefa..."
- Lucas (Implementer) em estado `working` com speech bubble "Escrevendo módulo de auth..."
- Ana (Documenter) se movendo em direção à Sala Notion
- Chat lateral com mensagens aparecendo: status de cada agente
- Indicador de progresso ou tokens sendo consumidos (discreto, no chrome lateral)

**Tela 3 — Popover de agente**
- Clicar no Implementer abre popover com status atual e botão "Falar com ele"

**Tela 4 — Estado de reunião**
- Vários agentes se moveram pra Sala de Reunião central
- Speech bubbles simultâneos (ou em sequência)

---

### Restrições de design

- **Desktop-first.** Não otimizar pra mobile
- **Dark theme** — fundo escuro no chrome lateral, paleta do escritório sóbria
- **Sem avatar do usuário** no escritório. O usuário é observador, não personagem
- **Status real, não teatro.** Speech bubbles devem parecer que refletem o que o agente realmente está fazendo — não frases genéricas inventadas
- **Chat lateral não pode dominar.** O escritório é a estrela. O chat é suporte

---

### Referências visuais

- Gather.town (layout de escritório top-down, câmera onisciente)
- Stardew Valley (paleta pixel art cozy, detalhes ambientais)
- Slack / Linear (qualidade do chrome lateral, tipografia limpa)
- Linear.app (dark theme bem executado, sem ser pesado)

---

### Entregável esperado

Um protótipo interativo HTML/CSS (ou React + Tailwind) que:
1. Mostra as 4 telas descritas acima
2. O pixel art pode ser **representado com CSS** (blocos coloridos, bordas, sem precisar de sprites reais nesta fase) — o objetivo é validar layout e UX, não o visual final
3. O popover de agente deve funcionar (clicar abre, clicar fora fecha)
4. O chat lateral deve parecer com streaming (pode usar animação CSS para simular)
5. Navegação entre as 4 telas com botões ou tabs simples

**Não precisa de:** backend real, Socket.io, código TypeScript final. Isso é um protótipo de UX/layout.

---

### Perguntas que o protótipo deve ajudar a responder

Ao revisar o protótipo, queremos decidir:

1. O escritório cabe bem com 7 agentes visíveis ao mesmo tempo?
2. Speech bubbles ficam legíveis sobre os sprites?
3. O popover de agente encaixa sem bloquear a visão do escritório?
4. A proporção 75% canvas / 25% chat funciona, ou precisa ajustar?
5. As salas especiais (Notion, GitHub) comunicam visualmente sua função?
6. O dark theme fica cozy ou pesado demais?
7. Tem algo na UX que parece errado quando você vê funcionando?
