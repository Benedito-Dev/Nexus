#!/bin/bash
# validate-documentation.sh — Nexus
# Stop hook para o Documenter

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Validando documentacao (Nexus)..."

# Task number
TASK_NUM="${TASK_NUM:-}"
if [ -z "$TASK_NUM" ]; then
  for search_dir in workspace/implementations workspace/reviews workspace/plans; do
    if [ -d "$search_dir" ]; then
      LATEST_ARTIFACT=$(find "$search_dir" -name "*-task*.md" -type f -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -1)
      if [ -n "${LATEST_ARTIFACT:-}" ]; then
        TASK_NUM=$(basename "$LATEST_ARTIFACT" | grep -oE 'task[0-9]+' | grep -oE '[0-9]+' || echo "")
        if [ -n "$TASK_NUM" ]; then break; fi
      fi
    fi
  done
fi

TASK_NUM="${TASK_NUM:-UNKNOWN}"
echo -e "${GREEN}OK${NC} Task: $TASK_NUM"

# ==============================================================================
# VALIDACAO 1: STATUS.md (CRITICO)
# ==============================================================================

STATUS_FILE="workspace/STATUS.md"

if [ ! -f "$STATUS_FILE" ]; then
  echo -e "${RED}ERRO: workspace/STATUS.md nao encontrado!${NC}" >&2
  exit 2
fi

if [ "$TASK_NUM" != "UNKNOWN" ]; then
  if ! grep -qE "Task ${TASK_NUM}" "$STATUS_FILE"; then
    echo -e "${RED}ERRO: Task $TASK_NUM nao documentada no STATUS.md!${NC}" >&2
    exit 2
  fi
  if ! grep -qE "Task ${TASK_NUM}.*COMPLETE|COMPLETA" "$STATUS_FILE"; then
    echo -e "${RED}ERRO: Task $TASK_NUM existe no STATUS.md mas nao esta COMPLETE!${NC}" >&2
    exit 2
  fi
  echo -e "${GREEN}OK${NC} STATUS.md: Task $TASK_NUM COMPLETE"
fi

# ==============================================================================
# VALIDACAO 2: shared/eventos.md (se protocolo mudou)
# ==============================================================================

# Verificar se shared/ foi modificado recentemente
if git rev-parse --git-dir > /dev/null 2>&1; then
  SHARED_CHANGED=$(git diff --name-only HEAD 2>/dev/null | grep '^shared/' | wc -l || echo 0)
  if [ "$SHARED_CHANGED" -gt 0 ]; then
    if [ -f "shared/eventos.md" ] || [ -f "docs/eventos.md" ]; then
      echo -e "${GREEN}OK${NC} Protocolo documentado (shared/ mudou e eventos.md existe)"
    else
      echo -e "${YELLOW}AVISO: shared/ foi modificado mas eventos.md nao encontrado${NC}" >&2
      echo -e "${YELLOW}  Documente os novos/modificados eventos em shared/eventos.md ou docs/eventos.md${NC}" >&2
    fi
  fi
fi

# ==============================================================================
# VALIDACAO 3: CHANGELOG.md (se existir)
# ==============================================================================

CHANGELOG_FILE=""
for candidate in "CHANGELOG.md" "docs/CHANGELOG.md"; do
  if [ -f "$candidate" ]; then
    CHANGELOG_FILE="$candidate"
    break
  fi
done

if [ -z "$CHANGELOG_FILE" ]; then
  echo -e "${YELLOW}INFO: CHANGELOG.md nao encontrado (opcional)${NC}"
else
  if grep -q "## \[Unreleased\]" "$CHANGELOG_FILE"; then
    echo -e "${GREEN}OK${NC} CHANGELOG.md atualizado"
  else
    echo -e "${YELLOW}AVISO: CHANGELOG sem secao [Unreleased]${NC}" >&2
  fi
fi

# ==============================================================================
# VALIDACAO 4: Git commit (CRITICO)
# ==============================================================================

if git rev-parse --git-dir > /dev/null 2>&1; then
  LAST_COMMIT=$(git log -1 --oneline 2>/dev/null || echo "")

  if [ -z "$LAST_COMMIT" ]; then
    echo -e "${RED}ERRO: Nenhum commit encontrado!${NC}" >&2
    exit 2
  fi

  echo "Ultimo commit: $LAST_COMMIT"

  # Verificar Conventional Commits com scopes do Nexus
  if ! echo "$LAST_COMMIT" | grep -qE '^[a-f0-9]+ (feat|fix|docs|refactor|perf|test|chore|style|ci|build)(\((frontend|backend|shared|canvas|agentes|websocket|llm|orquestrador|projetos|auth|notion|github|docs|config)\))?:'; then
    echo -e "${YELLOW}AVISO: Commit pode nao seguir Conventional Commits com scopes do Nexus${NC}" >&2
    echo -e "${YELLOW}  Scopes validos: frontend, backend, shared, canvas, agentes, websocket, llm, etc.${NC}" >&2
  fi

  COMMIT_TIME=$(git log -1 --format=%ct 2>/dev/null || echo "0")
  NOW=$(date +%s)
  MINUTES=$(( (NOW - COMMIT_TIME) / 60 ))

  if [ "$MINUTES" -gt 30 ]; then
    echo -e "${YELLOW}AVISO: Ultimo commit tem ${MINUTES}min (esperado: <30min)${NC}" >&2
  fi

  echo -e "${GREEN}OK${NC} Commit criado (${MINUTES}min atras)"
fi

# ==============================================================================
# VALIDACAO 5: JSDoc em arquivos recentes (amostra)
# ==============================================================================

echo ""
echo "Verificando JSDoc (amostra)..."

RECENT_TS=0
WITH_JSDOC=0

for ws in frontend backend shared; do
  if [ ! -d "$ws/src" ]; then continue; fi
  FILES=$(find "$ws/src" -name "*.ts" -o -name "*.tsx" | xargs ls -t 2>/dev/null | head -3)
  for f in $FILES; do
    RECENT_TS=$((RECENT_TS + 1))
    if grep -q '/\*\*' "$f" 2>/dev/null; then
      WITH_JSDOC=$((WITH_JSDOC + 1))
    fi
  done
done

if [ "$RECENT_TS" -eq 0 ]; then
  echo -e "${YELLOW}INFO: Sem arquivos .ts/.tsx recentes para verificar JSDoc${NC}"
elif [ "$WITH_JSDOC" -eq 0 ]; then
  echo -e "${YELLOW}AVISO: Nenhum dos $RECENT_TS arquivos recentes tem JSDoc${NC}" >&2
else
  echo -e "${GREEN}OK${NC} JSDoc presente em $WITH_JSDOC/$RECENT_TS arquivos recentes"
fi

# ==============================================================================
# SUCESSO
# ==============================================================================

echo ""
echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}VALIDACOES DE DOCUMENTACAO PASSARAM!${NC}"
echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}OK${NC} STATUS.md: Task $TASK_NUM COMPLETE"
echo -e "${GREEN}OK${NC} Commit: Criado"
echo ""
echo -e "${GREEN}Task $TASK_NUM finalizada com sucesso!${NC}"
echo ""

exit 0
