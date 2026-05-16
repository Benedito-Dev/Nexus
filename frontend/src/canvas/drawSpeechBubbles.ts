import type { AgentRenderState } from '../office/state/types';
import { SPRITE_H, SPRITE_W } from './constants';

const BUBBLE_PADDING_X = 10;
const BUBBLE_PADDING_Y = 6;
const BUBBLE_FONT = '11px system-ui, sans-serif';
const BUBBLE_MAX_WIDTH = 200;
const ARROW_H = 5;

/**
 * Renderiza speech bubbles sobre os agentes que têm texto ativo.
 *
 * Bubbles são auto-gerenciadas pelo AgentStateManager (expiram por tempo).
 * Esta função só renderiza — não gerencia estado.
 *
 * @param ctx - Contexto 2D do canvas (imageSmoothingEnabled deve ser false)
 * @param agents - Estados atuais dos agentes
 */
export function drawSpeechBubbles(ctx: CanvasRenderingContext2D, agents: AgentRenderState[]): void {
  ctx.font = BUBBLE_FONT;
  ctx.textBaseline = 'middle';
  ctx.textAlign = 'center';

  for (const agent of agents) {
    if (agent.speechBubble === null) continue;

    const { text } = agent.speechBubble;
    const agentCenterX = Math.round(agent.x);
    const agentTopY = Math.round(agent.y - SPRITE_H);

    const textW = Math.min(ctx.measureText(text).width, BUBBLE_MAX_WIDTH);
    const bubbleW = textW + BUBBLE_PADDING_X * 2;
    const bubbleH = 14 + BUBBLE_PADDING_Y * 2; // aprox 1 linha
    const bubbleX = agentCenterX - bubbleW / 2;
    const bubbleY = agentTopY - bubbleH - ARROW_H - 4;

    // Fundo branco do bubble
    ctx.fillStyle = 'oklch(0.95 0.005 250)';
    roundRect(ctx, bubbleX, bubbleY, bubbleW, bubbleH, 6);
    ctx.fill();

    // Sombra sutil
    ctx.shadowColor = 'rgba(0,0,0,0.4)';
    ctx.shadowBlur = 6;
    ctx.shadowOffsetY = 2;
    ctx.fill();
    ctx.shadowColor = 'transparent';
    ctx.shadowBlur = 0;
    ctx.shadowOffsetY = 0;

    // Setinha apontando para baixo
    ctx.fillStyle = 'oklch(0.95 0.005 250)';
    ctx.beginPath();
    ctx.moveTo(agentCenterX - 4, bubbleY + bubbleH);
    ctx.lineTo(agentCenterX + 4, bubbleY + bubbleH);
    ctx.lineTo(agentCenterX, bubbleY + bubbleH + ARROW_H);
    ctx.closePath();
    ctx.fill();

    // Texto
    ctx.fillStyle = 'oklch(0.18 0.008 250)';
    ctx.font = BUBBLE_FONT;
    ctx.fillText(text, agentCenterX, bubbleY + bubbleH / 2, BUBBLE_MAX_WIDTH);
  }

  // Reset
  ctx.textAlign = 'left';
  ctx.textBaseline = 'alphabetic';
}

/** Helper para desenhar retângulo com cantos arredondados */
function roundRect(
  ctx: CanvasRenderingContext2D,
  x: number,
  y: number,
  w: number,
  h: number,
  r: number,
): void {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + w - r, y);
  ctx.quadraticCurveTo(x + w, y, x + w, y + r);
  ctx.lineTo(x + w, y + h - r);
  ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  ctx.lineTo(x + r, y + h);
  ctx.quadraticCurveTo(x, y + h, x, y + h - r);
  ctx.lineTo(x, y + r);
  ctx.quadraticCurveTo(x, y, x + r, y);
  ctx.closePath();
}
