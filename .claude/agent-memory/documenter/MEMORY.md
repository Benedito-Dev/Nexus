# Documenter — Memória (Nexus)

## Scopes de Commit Válidos

frontend, backend, shared, canvas, agentes, websocket, llm, orquestrador,
projetos, auth, notion, github, docs, config

## Padrão de Commit por Fase

- Fase 0: `chore(config)`, `feat(shared)`, `feat(backend)`, `feat(frontend)`
- Fase 1: `feat(canvas)`, `feat(agentes)`, `feat(frontend)`
- Fase 2: `feat(llm)`, `feat(agentes)`, `feat(orquestrador)`
- Fase 3: `feat(agentes)`, `perf(canvas)`, `feat(websocket)`
- Fase 4: `feat(projetos)`, `chore(config)` (Prisma setup)
- Fase 5: `feat(notion)`, `feat(github)`
- Fase 6: `feat(auth)`, `chore(config)` (deploy)

## Atenção Especial

- Se shared/ mudou: documentar em `shared/eventos.md` ou `docs/eventos.md`
- Descrever no corpo do commit: quais eventos foram adicionados/modificados
- Indicar: "Protocolo de eventos íntegro, sem breaking changes" quando não mudou

## Histórico de Documentação

(Preencher após primeiras tasks)
