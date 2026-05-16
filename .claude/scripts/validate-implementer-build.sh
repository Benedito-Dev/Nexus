#!/bin/bash
# validate-implementer-build.sh — Nexus
# SubagentStop hook: double-check de build antes do Implementer retornar

set -euo pipefail

cat > /dev/null 2>&1 || true

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "Double-check: validando builds do Nexus..." >&2

BUILD_FAILED=false

for ws in frontend backend shared; do
  if [ ! -d "$ws" ] || [ ! -f "$ws/package.json" ]; then
    continue
  fi

  if ! grep -q '"build"' "$ws/package.json" 2>/dev/null; then
    continue
  fi

  if ! (cd "$ws" && npm run build) > /tmp/subagent-build-$ws.log 2>&1; then
    echo -e "${RED}BUILD FALHOU em $ws/ no double-check!${NC}" >&2
    tail -10 /tmp/subagent-build-$ws.log >&2

    ERRMSG=$(tail -5 /tmp/subagent-build-$ws.log | tr '\n' ' ' | sed 's/"/\\"/g')
    cat <<EOF
{
  "decision": "block",
  "reason": "BUILD FALHOU em $ws/ no double-check. Implementer precisa corrigir antes de retornar. Erro: ${ERRMSG}"
}
EOF
    exit 0
  fi

  echo -e "${GREEN}Double-check: $ws/ BUILD OK${NC}" >&2
done

# Verificar implementation notes
IMPL_DIR="workspace/implementations"
LATEST_IMPL=""
if [ -d "$IMPL_DIR" ]; then
  LATEST_IMPL=$(find "$IMPL_DIR" -name "impl-*.md" -type f -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -1 || true)
fi

if [ -z "${LATEST_IMPL:-}" ]; then
  cat <<EOF
{
  "decision": "block",
  "reason": "Implementation notes nao encontradas em workspace/implementations/. Crie impl-[modulo]-[desc]-taskN.md antes de retornar."
}
EOF
  exit 0
fi

echo -e "${GREEN}Double-check: Implementation notes OK${NC}" >&2
echo -e "${GREEN}Double-check COMPLETO: Implementer pode retornar.${NC}" >&2
exit 0
