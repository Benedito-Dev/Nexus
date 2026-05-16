import { COLORS, OFFICE_H, OFFICE_W, TILE } from './constants';

/**
 * Renderiza o piso do escritório com tiles alternados de madeira.
 *
 * Deve ser chamada no início de cada frame, antes dos outros draws.
 *
 * @param ctx - Contexto 2D do canvas (imageSmoothingEnabled deve ser false)
 */
export function drawFloor(ctx: CanvasRenderingContext2D): void {
  const cols = OFFICE_W / TILE;
  const rows = OFFICE_H / TILE;

  for (let row = 0; row < rows; row++) {
    for (let col = 0; col < cols; col++) {
      // Alternância a cada 2 colunas para efeito de tábuas
      const even = Math.floor(col / 2) % 2 === 0;
      ctx.fillStyle = even ? COLORS.floor : COLORS.floor2;
      ctx.fillRect(col * TILE, row * TILE, TILE, TILE);
    }
  }

  // Linhas de junção entre tábuas
  ctx.strokeStyle = COLORS.floorLine;
  ctx.lineWidth = 1;
  ctx.globalAlpha = 0.6;

  for (let col = 2; col < cols; col += 2) {
    ctx.beginPath();
    ctx.moveTo(col * TILE - 0.5, 0);
    ctx.lineTo(col * TILE - 0.5, OFFICE_H);
    ctx.stroke();
  }

  ctx.globalAlpha = 1;
}
