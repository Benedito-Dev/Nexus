#!/bin/bash
# session-setup.sh — Nexus
# SessionStart hook: valida o ambiente do monorepo ao iniciar a sessão

set -euo pipefail

ERRORS=0
WARNINGS=0
CONTEXT=""

# =====================================================================
# CHECK 1: Node.js
# =====================================================================
if ! command -v node &>/dev/null; then
  CONTEXT+="ERROR: Node.js nao encontrado. Instale antes de continuar.\n"
  ERRORS=$((ERRORS + 1))
else
  NODE_VERSION=$(node --version)
  CONTEXT+="Node.js: $NODE_VERSION\n"
fi

# =====================================================================
# CHECK 2: pnpm (gerenciador do monorepo)
# =====================================================================
if ! command -v pnpm &>/dev/null; then
  CONTEXT+="WARNING: pnpm nao encontrado. Instale: npm install -g pnpm\n"
  WARNINGS=$((WARNINGS + 1))
else
  PNPM_VERSION=$(pnpm --version)
  CONTEXT+="pnpm: $PNPM_VERSION\n"
fi

# =====================================================================
# CHECK 3: Workspaces do monorepo
# =====================================================================
for workspace in frontend backend shared; do
  if [ -d "$workspace" ]; then
    CONTEXT+="Workspace $workspace/: OK\n"
    # node_modules do workspace
    if [ ! -d "$workspace/node_modules" ] && [ -f "$workspace/package.json" ]; then
      CONTEXT+="WARNING: $workspace/node_modules nao encontrado. Rode 'pnpm install'.\n"
      WARNINGS=$((WARNINGS + 1))
    fi
  else
    CONTEXT+="INFO: Workspace $workspace/ ainda nao criado (pode ser normal na Fase 0).\n"
  fi
done

# =====================================================================
# CHECK 4: pnpm-workspace.yaml (monorepo configurado)
# =====================================================================
if [ -f "pnpm-workspace.yaml" ]; then
  CONTEXT+="pnpm-workspace.yaml: OK\n"
else
  CONTEXT+="INFO: pnpm-workspace.yaml nao encontrado. Sera criado na Fase 0.\n"
fi

# =====================================================================
# CHECK 5: shared/ — protocolo de eventos (coração do Nexus)
# =====================================================================
if [ -d "shared" ]; then
  if [ -f "shared/src/events.ts" ] || [ -f "shared/events.ts" ]; then
    CONTEXT+="Protocolo de eventos (shared/): OK\n"
  else
    CONTEXT+="WARNING: shared/ existe mas events.ts nao encontrado. Crie o protocolo antes de implementar.\n"
    WARNINGS=$((WARNINGS + 1))
  fi
fi

# =====================================================================
# CHECK 6: .env (se .env.example existe)
# =====================================================================
for dir in . backend frontend; do
  if [ -f "$dir/.env.example" ] && [ ! -f "$dir/.env" ]; then
    CONTEXT+="WARNING: $dir/.env.example existe mas $dir/.env nao. Configure as variaveis de ambiente.\n"
    WARNINGS=$((WARNINGS + 1))
  fi
done

# =====================================================================
# CHECK 7: Git branch
# =====================================================================
BRANCH=$(git branch --show-current 2>/dev/null || echo "(sem git)")
CONTEXT+="Git branch: $BRANCH\n"

# =====================================================================
# CHECK 8: Arquivos modificados
# =====================================================================
if git rev-parse --git-dir > /dev/null 2>&1; then
  MODIFIED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  CONTEXT+="Arquivos modificados: $MODIFIED\n"
fi

# =====================================================================
# CHECK 9: workspace/ para multi-agent
# =====================================================================
if [ ! -d "workspace" ]; then
  CONTEXT+="WARNING: workspace/ nao existe. Agents precisam dele para artifacts.\n"
  CONTEXT+="  Crie: mkdir -p workspace/{plans,implementations,reviews}\n"
  WARNINGS=$((WARNINGS + 1))
else
  CONTEXT+="workspace/: OK\n"
fi

# =====================================================================
# CHECK 10: Fase atual do roadmap (via STATUS.md)
# =====================================================================
if [ -f "workspace/STATUS.md" ]; then
  LAST_TASK=$(grep -oE 'Task [0-9]+' workspace/STATUS.md | tail -1 || echo "")
  if [ -n "$LAST_TASK" ]; then
    CONTEXT+="Ultima task registrada: $LAST_TASK\n"
  fi
fi

# =====================================================================
# OUTPUT
# =====================================================================
echo "=== Nexus — Personal Agents Session Setup ==="
echo -e "$CONTEXT"

if [ "$ERRORS" -gt 0 ]; then
  echo "RESULTADO: $ERRORS erros, $WARNINGS warnings"
  echo "Corrija erros antes de comecar."
else
  echo "RESULTADO: Ambiente OK ($WARNINGS warnings)"
  echo "Monorepo: frontend/ + backend/ + shared/"
fi

exit 0
