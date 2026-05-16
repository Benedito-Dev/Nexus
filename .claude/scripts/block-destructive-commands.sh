#!/bin/bash
# block-destructive-commands.sh — Nexus
# PreToolUse hook: bloqueia comandos destrutivos em Bash
#
# Exit 2 = bloqueia (stderr volta pro Claude como erro)
# Exit 0 = permite

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# =====================================================================
# 1. Filesystem crítico
# =====================================================================
if echo "$COMMAND" | grep -iE 'rm\s+(-rf|-fr)\s+(/|~|shared/|frontend/|backend/|\.claude/|workspace/|node_modules/)' > /dev/null; then
  echo "BLOQUEADO: rm -rf em diretorio critico do Nexus detectado!" >&2
  echo "Deletar shared/, frontend/, backend/, .claude/ ou workspace/ nao e permitido." >&2
  exit 2
fi

if echo "$COMMAND" | grep -iE 'rm\s+(-rf|-fr)\s+\.git' > /dev/null; then
  echo "BLOQUEADO: rm -rf .git detectado! Isso apaga todo o historico do Nexus." >&2
  exit 2
fi

# =====================================================================
# 2. Git destrutivo
# =====================================================================
if echo "$COMMAND" | grep -iE 'git\s+push\s+.*--force.*\b(main|master)\b' > /dev/null; then
  echo "BLOQUEADO: git push --force em main/master!" >&2
  echo "Force push em branch principal pode apagar commits." >&2
  exit 2
fi

if echo "$COMMAND" | grep -iE 'git\s+reset\s+--hard\s+HEAD~' > /dev/null; then
  echo "AVISO: git reset --hard pode perder commits nao pushados." >&2
  echo "Considere 'git revert' para reverter com seguranca." >&2
  # Avisa mas nao bloqueia
fi

# =====================================================================
# 3. Banco de dados (Prisma — Fase 4+)
# =====================================================================
if echo "$COMMAND" | grep -iE 'prisma\s+migrate\s+reset' > /dev/null; then
  echo "BLOQUEADO: 'prisma migrate reset' apaga TODO o banco!" >&2
  echo "Faca backup antes ou use 'prisma migrate dev'." >&2
  exit 2
fi

if echo "$COMMAND" | grep -iE 'prisma\s+db\s+push.*--accept-data-loss' > /dev/null; then
  echo "BLOQUEADO: 'prisma db push --accept-data-loss' pode causar perda de dados!" >&2
  exit 2
fi

if echo "$COMMAND" | grep -iE '\bDROP\s+(TABLE|DATABASE|SCHEMA)\b' > /dev/null; then
  echo "BLOQUEADO: DROP TABLE/DATABASE/SCHEMA detectado!" >&2
  exit 2
fi

# =====================================================================
# 4. Protecao do protocolo de eventos (shared/)
# =====================================================================
# Impede apagar o schema de eventos sem confirmacao explicita
if echo "$COMMAND" | grep -iE 'rm\s+.*shared/.*events' > /dev/null; then
  echo "BLOQUEADO: Tentativa de deletar arquivo de eventos em shared/!" >&2
  echo "O protocolo de eventos e o coracao do Nexus — nao delete sem migrar os dois lados." >&2
  exit 2
fi

# =====================================================================
# COMANDO PERMITIDO
# =====================================================================
exit 0
