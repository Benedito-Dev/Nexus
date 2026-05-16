import { OFFICE } from '../office/data/office-layout';
import type { RoomDefinition } from '../office/data/office-layout';
import { COLORS, TILE } from './constants';

/** Mapa de cores de fundo por tipo de sala */
const ROOM_FILL: Record<RoomDefinition['kind'], string> = {
  notion: COLORS.notionFloor,
  github: COLORS.githubFloor,
  meeting: COLORS.carpet,
};

/** Mapa de cores de borda por tipo de sala */
const ROOM_BORDER: Record<RoomDefinition['kind'], string> = {
  notion: 'oklch(0.50 0.020 80)',
  github: 'oklch(0.45 0.030 280)',
  meeting: 'oklch(0.45 0.035 165)',
};

/**
 * Renderiza as salas especiais do escritório como retângulos coloridos com label.
 *
 * Deve ser chamada após drawFloor() para sobrepor o piso nas áreas das salas.
 *
 * @param ctx - Contexto 2D do canvas (imageSmoothingEnabled deve ser false)
 */
export function drawRooms(ctx: CanvasRenderingContext2D): void {
  const rooms = Object.values(OFFICE.rooms);

  for (const room of rooms) {
    const px = room.x * TILE;
    const py = room.y * TILE;
    const pw = room.w * TILE;
    const ph = room.h * TILE;

    // Fundo da sala
    ctx.fillStyle = ROOM_FILL[room.kind];
    ctx.fillRect(px, py, pw, ph);

    // Borda interna
    ctx.strokeStyle = ROOM_BORDER[room.kind];
    ctx.lineWidth = 2;
    ctx.strokeRect(px + 1, py + 1, pw - 2, ph - 2);

    // Label da sala
    ctx.fillStyle = 'oklch(0.78 0.02 60)';
    ctx.font = 'bold 8px monospace';
    ctx.textBaseline = 'top';
    ctx.fillText(room.label, px + 8, py + 6);
  }
}
