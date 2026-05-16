#!/bin/bash
# update-status-after-agent.sh — Nexus
# SubagentStop hook: atualiza workspace/STATUS.md quando um agent termina

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

AGENT_NAME="${1:-}"

if [ -z "$AGENT_NAME" ] && [ ! -t 0 ]; then
  STDIN_DATA=$(cat)
  if [ -n "$STDIN_DATA" ] && command -v jq &>/dev/null; then
    AGENT_NAME=$(echo "$STDIN_DATA" | jq -r '.agent_type // .subagent_type // empty' 2>/dev/null || true)
  fi
fi

if [ -z "$AGENT_NAME" ]; then
  echo -e "${YELLOW}AVISO: Nome do agent nao identificado${NC}"
  exit 0
fi

case "$AGENT_NAME" in
  strategist|frontend-implementer|backend-implementer|reviewer|documenter) ;;
  *)
    echo -e "${YELLOW}AVISO: Agent '$AGENT_NAME' nao faz parte do workflow Nexus — pulando${NC}"
    exit 0
    ;;
esac

# Extrair TASK_NUM
TASK_NUM=""
for dir in workspace/implementations workspace/reviews workspace/plans; do
  if [ -d "$dir" ]; then
    LATEST_FILE=$(find "$dir" -name "*-task*.md" -type f -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -1)
    if [ -n "${LATEST_FILE:-}" ]; then
      TASK_NUM=$(basename "$LATEST_FILE" | grep -oE 'task[0-9]+' | sed 's/task//' || echo "")
      if [ -n "$TASK_NUM" ]; then break; fi
    fi
  fi
done

TASK_NUM="${TASK_NUM:-unknown}"

STATUS_FILE="workspace/STATUS.md"

if [ ! -f "$STATUS_FILE" ]; then
  mkdir -p workspace
  cat > "$STATUS_FILE" << 'EOF'
# Workflow Status — Nexus

**Projeto:** Nexus — Plataforma visual de orquestração de agentes IA
**Stack:** React + Vite + Canvas | Node.js + TypeScript + Fastify + Socket.io | shared/ (protocolo de eventos)
**Última atualização:** Auto-gerado por hooks

---

## Tasks Concluídas

(Conclusão dos agents será registrada abaixo automaticamente)

EOF
fi

# Deduplicacao
TIMESTAMP_LOCAL=$(date +"%d/%m/%Y %H:%M:%S")
FINGERPRINT="<!-- dedup:${AGENT_NAME}:${TASK_NUM} -->"

if grep -qF "$FINGERPRINT" "$STATUS_FILE" 2>/dev/null; then
  echo -e "${YELLOW}AVISO: Entry duplicado (${AGENT_NAME}, Task #${TASK_NUM}) — pulando${NC}"
  exit 0
fi

cat >> "$STATUS_FILE" << EOF

---

${FINGERPRINT}
### Agent Concluído: $AGENT_NAME

**Task:** #$TASK_NUM
**Timestamp:** $TIMESTAMP_LOCAL
**Agent:** $AGENT_NAME
**Status:** Concluído

EOF

echo -e "${GREEN}OK${NC} STATUS.md atualizado — $AGENT_NAME (Task #$TASK_NUM)"
exit 0
