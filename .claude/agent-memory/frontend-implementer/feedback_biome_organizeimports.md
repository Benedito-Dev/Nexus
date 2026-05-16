---
name: feedback-biome-organizeimports
description: Biome ordena imports com type imports antes de value imports — usar --fix para corrigir automaticamente
metadata:
  type: feedback
---

Biome com `organizeImports: enabled` ordena imports colocando `import type` antes de `import` (value imports). Escrever na ordem errada gera erro.

**Why:** O Biome tem opinião forte sobre ordem de imports — type imports antes, value imports depois. Fácil de errar ao escrever manualmente.

**How to apply:**
- Rodar `./node_modules/.bin/biome check --fix src/` após escrever código novo para corrigir automaticamente
- O `--fix` corrige organização de imports e formatação automaticamente (safe fixes)
- Biome binary fica em `frontend/node_modules/.bin/biome` — usar caminho relativo ou via pnpm

Relacionado: [[feedback-tsconfig-vite]]
