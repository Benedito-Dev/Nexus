import type { AgentRenderState } from '../office/state/types';
import { SPRITE_H, SPRITE_W } from './constants';

/**
 * Renderiza todos os agentes no canvas como retângulos coloridos (Fase 0).
 *
 * Sprites pixel art completos são Fase 1. Por ora, cada agente é um
 * retângulo de SPRITE_W × SPRITE_H com a cor chatColor do agente,
 * centrado na posição do agente em pixels.
 *
 * Deve ser chamada dentro do game loop (requestAnimationFrame).
 * Opera em <5ms para manter budget de 16ms/frame (60fps).
 *
 * @param ctx - Contexto 2D do canvas (imageSmoothingEnabled deve ser false)
 * @param agents - Estados atuais dos agentes para renderizar
 */
export function drawAgents(ctx: CanvasRenderingContext2D, agents: AgentRenderState[]): void {
  for (const agent of agents) {
    const drawX = Math.round(agent.x - SPRITE_W / 2);
    const drawY = Math.round(agent.y - SPRITE_H);

    // Sombra do sprite
    ctx.fillStyle = 'rgba(0,0,0,0.35)';
    ctx.beginPath();
    ctx.ellipse(Math.round(agent.x), Math.round(agent.y), SPRITE_W / 2, 3, 0, 0, Math.PI * 2);
    ctx.fill();

    // Corpo do agente (retângulo colorido — Fase 0)
    ctx.fillStyle = agent.color;
    ctx.fillRect(drawX, drawY, SPRITE_W, SPRITE_H);

    // Borda escura para dar volume
    ctx.strokeStyle = 'rgba(0,0,0,0.4)';
    ctx.lineWidth = 1;
    ctx.strokeRect(drawX + 0.5, drawY + 0.5, SPRITE_W - 1, SPRITE_H - 1);

    // Label com nome do agente
    ctx.font = '6px monospace';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'bottom';

    // Sombra do texto
    ctx.fillStyle = 'rgba(0,0,0,0.85)';
    ctx.fillText(agent.name, Math.round(agent.x) + 1, drawY - 1 + 1);
    ctx.fillText(agent.name, Math.round(agent.x) - 1, drawY - 1 - 1);

    // Texto do nome
    ctx.fillStyle = 'oklch(0.92 0.005 250)';
    ctx.fillText(agent.name, Math.round(agent.x), drawY - 1);

    // Indicador de estado no topo do sprite
    const stateColor = getStateColor(agent.state);
    if (stateColor !== null) {
      ctx.fillStyle = stateColor;
      ctx.fillRect(drawX + SPRITE_W - 5, drawY + 2, 4, 4);
    }
  }

  // Reset textAlign para não afetar outros draws
  ctx.textAlign = 'left';
}

/** Retorna a cor do indicador de estado, ou null para idle */
function getStateColor(state: AgentRenderState['state']): string | null {
  switch (state) {
    case 'thinking':
      return 'oklch(0.74 0.11 60)'; // amber
    case 'working':
      return 'oklch(0.72 0.12 220)'; // blue
    case 'moving':
      return 'oklch(0.72 0.10 150)'; // green
    case 'speaking':
      return 'oklch(0.78 0.10 85)'; // yellow
    case 'idle':
      return null;
  }
}
