#!/bin/bash
# validate-review.sh — Nexus
# Stop hook para o Reviewer

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Validando review do Reviewer (Nexus)..."

REVIEW_DIR="workspace/reviews"

if [ ! -d "$REVIEW_DIR" ]; then
  echo -e "${RED}ERRO: workspace/reviews/ nao existe!${NC}" >&2
  exit 2
fi

LATEST_REVIEW=$(find "$REVIEW_DIR" -name "review-*.md" -type f -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -1)

if [ -z "$LATEST_REVIEW" ]; then
  echo -e "${RED}ERRO: Review nao encontrada em workspace/reviews/${NC}" >&2
  exit 2
fi

REVIEW_FILENAME=$(basename "$LATEST_REVIEW")
echo -e "${GREEN}OK${NC} Review encontrada: $REVIEW_FILENAME"

# Nomenclatura
if ! echo "$REVIEW_FILENAME" | grep -qE '^review-[a-z0-9]+-[a-z0-9-]+-task[0-9]+\.md$'; then
  echo -e "${RED}ERRO: Nomenclatura incorreta: $REVIEW_FILENAME${NC}" >&2
  exit 2
fi
echo -e "${GREEN}OK${NC} Nomenclatura: OK"

TASK_NUM=$(echo "$REVIEW_FILENAME" | grep -oE 'task[0-9]+' | grep -oE '[0-9]+' || echo "")
REVIEW_CONTENT=$(cat "$LATEST_REVIEW")

# Score numerico
SCORE=$(echo "$REVIEW_CONTENT" | grep -oE '[0-9]+\.?[0-9]*/10' | head -1 || echo "")
if [ -z "$SCORE" ]; then
  echo -e "${RED}ERRO: Score numerico nao encontrado (formato: X/10)${NC}" >&2
  exit 2
fi

SCORE_VALUE=$(echo "$SCORE" | grep -oE '^[0-9]+\.?[0-9]*' || echo "0")
echo -e "${GREEN}OK${NC} Score: $SCORE"

if (( $(echo "$SCORE_VALUE < 0" | bc -l) )) || (( $(echo "$SCORE_VALUE > 10" | bc -l) )); then
  echo -e "${RED}ERRO: Score fora do range 0-10: $SCORE_VALUE${NC}" >&2
  exit 2
fi

# Decisao
DECISION=""
if echo "$REVIEW_CONTENT" | grep -qi "APPROVED"; then DECISION="APPROVED"
elif echo "$REVIEW_CONTENT" | grep -qi "REJECTED"; then DECISION="REJECTED"
elif echo "$REVIEW_CONTENT" | grep -qi "NEEDS.CHANGE\|NEEDS_CHANGE"; then DECISION="NEEDS_CHANGES"
fi

if [ -z "$DECISION" ]; then
  echo -e "${RED}ERRO: Decisao nao encontrada (APPROVED / REJECTED / NEEDS_CHANGES)${NC}" >&2
  exit 2
fi
echo -e "${GREEN}OK${NC} Decisao: $DECISION"

# Consistencia score vs decisao
if [ "$DECISION" = "APPROVED" ] && (( $(echo "$SCORE_VALUE < 7.0" | bc -l) )); then
  echo -e "${RED}ERRO: APPROVED com score $SCORE_VALUE < 7.0 — inconsistente!${NC}" >&2
  exit 2
fi

# Verificar principios do Nexus na review
if ! echo "$REVIEW_CONTENT" | grep -qi "protocolo\|shared\|eventos"; then
  echo -e "${YELLOW}AVISO: Review pode nao ter verificado integridade do protocolo de eventos${NC}" >&2
fi

if ! echo "$REVIEW_CONTENT" | grep -qi "fake.*real\|real.*fake\|mesma.*interface\|interface.*agent"; then
  echo -e "${YELLOW}AVISO: Review pode nao ter verificado se agentes fake/real usam mesma interface${NC}" >&2
fi

# Conformidade com plano
PLAN_DIR="workspace/plans"
if [ -d "$PLAN_DIR" ] && [ -n "${TASK_NUM:-}" ]; then
  MATCHING_PLAN=$(find "$PLAN_DIR" -name "plan-*-task${TASK_NUM}.md" -type f 2>/dev/null | head -1)
  if [ -n "$MATCHING_PLAN" ]; then
    if ! echo "$REVIEW_CONTENT" | grep -qi "conformidade\|CF-1\|CF-2"; then
      echo -e "${YELLOW}AVISO: Plan existe mas review nao tem secao de Conformidade${NC}" >&2
    else
      echo -e "${GREEN}OK${NC} Secao de conformidade presente"
    fi
  fi
fi

# Tamanho minimo
REVIEW_LINES=$(wc -l < "$LATEST_REVIEW")
if [ "$REVIEW_LINES" -lt 30 ]; then
  echo -e "${YELLOW}AVISO: Review curta ($REVIEW_LINES linhas)${NC}" >&2
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}VALIDACOES DA REVIEW PASSARAM!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}OK${NC} Score: $SCORE | Decisao: $DECISION"
echo ""

if [ "$DECISION" = "APPROVED" ]; then
  echo -e "${GREEN}Aprovado! Proximo: Documenter.${NC}"
elif [ "$DECISION" = "REJECTED" ]; then
  echo -e "${YELLOW}Rejeitado. Volte ao Implementer com feedback.${NC}"
else
  echo -e "${YELLOW}Mudancas necessarias. Volte ao Implementer.${NC}"
fi

exit 0
