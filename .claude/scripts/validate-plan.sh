#!/bin/bash
# validate-plan.sh — Nexus
# Stop hook para o Strategist
# Valida que o plano foi criado corretamente antes de retornar ao Orchestrator

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Validando plano do Strategist (Nexus)..."

# ==============================================================================
# VALIDACAO 1: Plano existe em workspace/plans/
# ==============================================================================

PLAN_DIR="workspace/plans"

if [ ! -d "$PLAN_DIR" ]; then
  echo -e "${RED}ERRO: diretorio workspace/plans/ nao existe!${NC}" >&2
  exit 2
fi

LATEST_PLAN=$(find "$PLAN_DIR" -name "plan-*.md" -type f -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -1)

if [ -z "$LATEST_PLAN" ]; then
  echo -e "${RED}ERRO: Nenhum plan-*.md encontrado em workspace/plans/${NC}" >&2
  echo -e "${YELLOW}Strategist deve criar: plan-[modulo]-[descricao]-taskN.md${NC}" >&2
  echo -e "${YELLOW}Modulos validos: frontend, backend, shared, agentes, canvas, websocket, llm, notion, github${NC}" >&2
  exit 2
fi

echo -e "${GREEN}OK${NC} Plano encontrado: $(basename "$LATEST_PLAN")"

TASK_NUM=$(basename "$LATEST_PLAN" | grep -oE 'task[0-9]+' | grep -oE '[0-9]+' || echo "")

# ==============================================================================
# VALIDACAO 2: Nomenclatura correta
# ==============================================================================

FILENAME=$(basename "$LATEST_PLAN")

if ! echo "$FILENAME" | grep -qE '^plan-[a-z0-9]+-[a-z0-9-]+-task[0-9]+\.md$'; then
  echo -e "${RED}ERRO: Nomenclatura incorreta: $FILENAME${NC}" >&2
  echo -e "${YELLOW}Formato esperado: plan-[modulo]-[descricao]-taskN.md${NC}" >&2
  echo -e "${YELLOW}Exemplos do Nexus:${NC}" >&2
  echo "  - plan-shared-protocolo-eventos-task1.md" >&2
  echo "  - plan-canvas-agentes-animados-task2.md" >&2
  echo "  - plan-backend-diretor-llm-task3.md" >&2
  exit 2
fi

if echo "$FILENAME" | grep -q '[A-Z]'; then
  echo -e "${RED}ERRO: Nomenclatura contem MAIUSCULAS: $FILENAME${NC}" >&2
  exit 2
fi

echo -e "${GREEN}OK${NC} Nomenclatura correta: $FILENAME"

# ==============================================================================
# VALIDACAO 3: Tamanho minimo
# ==============================================================================

MIN_LINES=50
LINE_COUNT=$(wc -l < "$LATEST_PLAN")

if [ "$LINE_COUNT" -lt "$MIN_LINES" ]; then
  echo -e "${RED}ERRO: Plano muito curto: $LINE_COUNT linhas (minimo: $MIN_LINES)${NC}" >&2
  echo -e "${YELLOW}Plano Nexus deve incluir:${NC}" >&2
  echo "  - Analise (contexto, estado atual, impacto no protocolo)" >&2
  echo "  - Minimo 2 alternativas com pros/contras" >&2
  echo "  - Fases de implementacao (shared/ -> backend -> frontend)" >&2
  echo "  - Riscos (latencia LLM, dessinc protocolo, canvas perf)" >&2
  echo "  - Estimativa de tempo" >&2
  exit 2
fi

echo -e "${GREEN}OK${NC} Tamanho adequado: $LINE_COUNT linhas"

# ==============================================================================
# VALIDACAO 4: Secoes minimas (warnings)
# ==============================================================================

CONTENT=$(cat "$LATEST_PLAN")

if ! echo "$CONTENT" | grep -qi "alternativa\|option\|abordagem"; then
  echo -e "${YELLOW}AVISO: Plano pode nao ter analise de alternativas (minimo 2 exigido)${NC}" >&2
fi

if ! echo "$CONTENT" | grep -qi "risco\|risk\|latencia\|dessinc"; then
  echo -e "${YELLOW}AVISO: Plano pode nao ter analise de riscos (latencia LLM? dessinc protocolo?)${NC}" >&2
fi

if ! echo "$CONTENT" | grep -qi "fase\|phase\|step"; then
  echo -e "${YELLOW}AVISO: Plano pode nao ter fases de implementacao${NC}" >&2
fi

if ! echo "$CONTENT" | grep -qi "shared\|protocolo\|evento"; then
  echo -e "${YELLOW}AVISO: Plano nao menciona impacto no protocolo de eventos (shared/)${NC}" >&2
fi

if ! echo "$CONTENT" | grep -qi "estimativa\|tempo\|time"; then
  echo -e "${YELLOW}AVISO: Plano pode nao ter estimativa de tempo${NC}" >&2
fi

# ==============================================================================
# SUCESSO
# ==============================================================================

echo ""
echo -e "${GREEN}Validacoes do plano passaram!${NC}"
echo -e "${GREEN}OK${NC} Arquivo: $FILENAME"
echo -e "${GREEN}OK${NC} Linhas: $LINE_COUNT"
echo ""

exit 0
