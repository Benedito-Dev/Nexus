---
name: feedback-tsconfig-vite
description: Configuração correta de tsconfig para projetos Vite — evitar tsc -b e composite references desnecessários
metadata:
  type: feedback
---

Não usar `tsc -b` no script de build do Vite. O Vite cuida da transpilação — o TypeScript deve rodar apenas como typecheck (`tsc --noEmit`).

**Why:** O `tsc -b` com tsconfig sem `outDir` emite arquivos `.js` na pasta `src/` ao lado dos `.ts`, quebrando o Biome (que então formata os `.js` gerados). Além disso, `references: [tsconfig.node.json]` exige `composite: true` no arquivo referenciado — configuração desnecessária para projetos Vite simples.

**How to apply:**
- Script `build` deve ser apenas `vite build`
- Script `typecheck` usa `tsc --noEmit`
- Adicionar `noEmit: true` no tsconfig.json principal
- Remover `references` do tsconfig.json se não for projeto composite real
- Adicionar `"types": ["vite/client"]` para que `import.meta.env` seja reconhecido

Relacionado: [[feedback-biome-organizeimports]]
