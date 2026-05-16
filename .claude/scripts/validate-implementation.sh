#!/bin/bash
# validate-implementation.sh — Nexus (monorepo)
# Stop hook para os agents frontend-implementer e backend-implementer
#
# Uso: ./.claude/scripts/validate-implementation.sh [frontend|backend|shared|all]
# Se nenhum argumento, detecta automaticamente pelo git diff

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TARGET="${1:-auto}"

echo "Validando implementacao Nexus (target: $TARGET)..."

# ==============================================================================
# DETECTAR WORKSPACES AFETADOS
# ==============================================================================

detect_changed_workspaces() {
  if git rev-parse --git-dir > /dev/null 2>&1; then
    CHANGED=$(git diff --name-only HEAD 2>/dev/null || git status --porcelain | awk '{print $2}')
    WORKSPACES=""
    if echo "$CHANGED" | grep -q '^frontend/'; then WORKSPACES="$WORKSPACES frontend"; fi
    if echo "$CHANGED" | grep -q '^backend/'; then WORKSPACES="$WORKSPACES backend"; fi
    if echo "$CHANGED" | grep -q '^shared/'; then WORKSPACES="$WORKSPACES shared"; fi
    echo "${WORKSPACES:-frontend backend}"  # default: ambos se nao detectar
  else
    echo "frontend backend"
  fi
}

if [ "$TARGET" = "auto" ]; then
  WORKSPACES=$(detect_changed_workspaces)
elif [ "$TARGET" = "all" ]; then
  WORKSPACES="frontend backend shared"
else
  WORKSPACES="$TARGET"
fi

echo "Workspaces a validar:$WORKSPACES"

# ==============================================================================
# VALIDACAO 1: BUILD DE CADA WORKSPACE (CRITICO)
# ==============================================================================

BUILD_FAILED=false

for ws in $WORKSPACES; do
  if [ ! -d "$ws" ]; then
    echo -e "${YELLOW}AVISO: Workspace $ws/ nao existe ainda (normal nas fases iniciais)${NC}"
    continue
  fi

  if [ ! -f "$ws/package.json" ]; then
    echo -e "${YELLOW}AVISO: $ws/package.json nao encontrado${NC}"
    continue
  fi

  if ! grep -q '"build"' "$ws/package.json" 2>/dev/null; then
    echo -e "${YELLOW}AVISO: $ws/ sem script 'build' no package.json${NC}"
    continue
  fi

  echo ""
  echo "Build: $ws/..."

  if ! (cd "$ws" && npm run build) > /tmp/build-$ws.log 2>&1; then
    echo -e "${RED}ERRO: BUILD FALHOU em $ws/!${NC}" >&2
    echo -e "${YELLOW}Ultimas 20 linhas:${NC}" >&2
    tail -20 /tmp/build-$ws.log >&2
    BUILD_FAILED=true
  else
    echo -e "${GREEN}OK${NC} Build $ws/: PASS"
  fi
done

if [ "$BUILD_FAILED" = "true" ]; then
  echo -e "${RED}Build falhou em um ou mais workspaces — corrija antes de prosseguir.${NC}" >&2
  exit 2
fi

# ==============================================================================
# VALIDACAO 2: TypeScript — ZERO ERROS
# ==============================================================================

TS_FAILED=false

for ws in $WORKSPACES; do
  if [ ! -d "$ws" ] || [ ! -f "$ws/tsconfig.json" ]; then
    continue
  fi

  echo ""
  echo "TypeScript: $ws/..."

  if ! (cd "$ws" && npx tsc --noEmit) > /tmp/tsc-$ws.log 2>&1; then
    echo -e "${RED}ERRO: TypeScript com erros em $ws/!${NC}" >&2
    cat /tmp/tsc-$ws.log >&2
    TS_FAILED=true
  else
    echo -e "${GREEN}OK${NC} TypeScript $ws/: 0 erros"
  fi
done

if [ "$TS_FAILED" = "true" ]; then
  echo -e "${RED}TypeScript com erros — corrija antes de prosseguir.${NC}" >&2
  exit 2
fi

# ==============================================================================
# VALIDACAO 3: Protocolo de eventos (shared/ integridade)
# ==============================================================================

echo ""
echo "Verificando integridade do protocolo de eventos..."

if [ -d "shared" ]; then
  # Verificar se algum workspace redefine tipos que deveriam vir de shared/
  PROTOCOL_VIOLATIONS=0

  for ws in frontend backend; do
    if [ ! -d "$ws/src" ]; then continue; fi

    # Procurar por definicoes de AgentEvent fora de shared/
    VIOLATIONS=$(grep -r "interface Agent.*Event\|type Agent.*Event" "$ws/src/" 2>/dev/null | grep -v "import" | wc -l || echo 0)
    if [ "$VIOLATIONS" -gt 0 ]; then
      echo -e "${YELLOW}AVISO: $ws/ pode ter tipos de eventos redefinidos fora de shared/!${NC}" >&2
      grep -r "interface Agent.*Event\|type Agent.*Event" "$ws/src/" 2>/dev/null | grep -v "import" >&2 || true
      PROTOCOL_VIOLATIONS=$((PROTOCOL_VIOLATIONS + 1))
    fi
  done

  if [ "$PROTOCOL_VIOLATIONS" -eq 0 ]; then
    echo -e "${GREEN}OK${NC} Protocolo de eventos: nenhuma redefinicao detectada"
  fi
fi

# ==============================================================================
# VALIDACAO 4: Implementation notes existem
# ==============================================================================

echo ""
echo "Verificando implementation notes..."

IMPL_DIR="workspace/implementations"

if [ ! -d "$IMPL_DIR" ]; then
  echo -e "${RED}ERRO: workspace/implementations/ nao existe!${NC}" >&2
  exit 2
fi

LATEST_IMPL=$(find "$IMPL_DIR" -name "impl-*.md" -type f -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -1)

if [ -z "$LATEST_IMPL" ]; then
  echo -e "${RED}ERRO: Implementation notes nao encontradas!${NC}" >&2
  echo -e "${YELLOW}Crie: workspace/implementations/impl-[modulo]-[descricao]-taskN.md${NC}" >&2
  exit 2
fi

IMPL_FILENAME=$(basename "$LATEST_IMPL")

if ! echo "$IMPL_FILENAME" | grep -qE '^impl-[a-z0-9]+-[a-z0-9-]+-task[0-9]+\.md$'; then
  echo -e "${RED}ERRO: Nomenclatura incorreta: $IMPL_FILENAME${NC}" >&2
  exit 2
fi

IMPL_LINES=$(wc -l < "$LATEST_IMPL")
echo -e "${GREEN}OK${NC} Implementation notes: $IMPL_FILENAME ($IMPL_LINES linhas)"

# ==============================================================================
# VALIDACAO 5: ESLint (se configurado)
# ==============================================================================

for ws in $WORKSPACES; do
  if [ ! -d "$ws" ]; then continue; fi

  HAS_ESLINT=false
  HAS_BIOME=false

  if [ -f "$ws/.eslintrc.json" ] || [ -f "$ws/.eslintrc.js" ] || [ -f "$ws/eslint.config.js" ]; then
    HAS_ESLINT=true
  fi
  if [ -f "$ws/biome.json" ] || [ -f "biome.json" ]; then
    HAS_BIOME=true
  fi

  if [ "$HAS_BIOME" = "true" ]; then
    echo ""
    echo "Biome lint: $ws/..."
    if (cd "$ws" && npx biome check src/ 2>/dev/null); then
      echo -e "${GREEN}OK${NC} Biome: sem issues em $ws/"
    else
      echo -e "${YELLOW}AVISO: Biome encontrou issues em $ws/${NC}"
    fi
  elif [ "$HAS_ESLINT" = "true" ]; then
    echo ""
    echo "ESLint: $ws/..."
    ESLINT_OUTPUT=$((cd "$ws" && npx eslint src/ --format json 2>/dev/null) || echo "[]")
    ERROR_COUNT=$(echo "$ESLINT_OUTPUT" | jq '[.[] | .errorCount] | add // 0' 2>/dev/null || echo 0)
    if [ "$ERROR_COUNT" -gt 0 ]; then
      echo -e "${RED}ERRO: ESLint encontrou $ERROR_COUNT erros em $ws/!${NC}" >&2
      exit 2
    fi
    echo -e "${GREEN}OK${NC} ESLint: 0 erros em $ws/"
  fi
done

# ==============================================================================
# VALIDACAO 6: Git status
# ==============================================================================

echo ""
if git rev-parse --git-dir > /dev/null 2>&1; then
  MODIFIED_COUNT=$(git status --porcelain | wc -l | tr -d ' ')
  if [ "$MODIFIED_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}AVISO: Nenhuma mudanca detectada no git${NC}"
  else
    echo -e "${GREEN}OK${NC} $MODIFIED_COUNT arquivo(s) modificado(s)"
  fi
fi

# ==============================================================================
# SUCESSO
# ==============================================================================

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}TODAS AS VALIDACOES PASSARAM!${NC}"
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}OK${NC} Build: PASS em todos os workspaces"
echo -e "${GREEN}OK${NC} TypeScript: 0 erros"
echo -e "${GREEN}OK${NC} Implementation notes: OK"
echo ""
echo -e "${GREEN}Implementacao aprovada para Review!${NC}"
echo ""

exit 0
