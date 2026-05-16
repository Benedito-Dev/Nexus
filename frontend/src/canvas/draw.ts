import type { AgentRenderState } from '../office/state/types';
import { drawAgents } from './drawAgents';
import { drawFloor } from './drawFloor';
import { drawRooms } from './drawRooms';
import { drawSpeechBubbles } from './drawSpeechBubbles';

/**
 * Ponto de entrada do frame de renderização do escritório.
 *
 * Ordem das camadas: piso → salas → agentes → speech bubbles.
 * Chamado a cada frame pelo game loop em Office.tsx.
 *
 * @param ctx - Contexto 2D do canvas (imageSmoothingEnabled deve ser false)
 * @param agents - Estados atuais de todos os agentes
 */
export function drawOffice(ctx: CanvasRenderingContext2D, agents: AgentRenderState[]): void {
  drawFloor(ctx);
  drawRooms(ctx);
  drawAgents(ctx, agents);
  drawSpeechBubbles(ctx, agents);
}
