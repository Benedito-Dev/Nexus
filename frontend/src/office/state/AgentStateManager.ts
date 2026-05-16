import { SPRITE_H, SPRITE_W, TILE } from '../../canvas/constants';
import type { AgentDefinition } from '../data/agents';
import type { AgentRenderState, AgentState, SpeechBubble } from './types';

/**
 * Gerencia o estado mutável de posição e animação dos agentes no canvas.
 *
 * Estado nunca acoplado ao React state — vive em useRef no componente Office.
 * Atualizado por eventos Socket.io e pelo update() do game loop.
 *
 * @example
 * const manager = new AgentStateManager();
 * manager.initialize(AGENTS);
 * // no game loop:
 * manager.update(delta);
 * const states = manager.getAll();
 */
export class AgentStateManager {
  private states = new Map<string, AgentRenderState>();

  /**
   * Inicializa os agentes com posição home e estado idle.
   *
   * @param agents - Definições estáticas dos agentes
   */
  initialize(agents: AgentDefinition[]): void {
    for (const agent of agents) {
      const x = agent.home.x * TILE;
      const y = agent.home.y * TILE;
      this.states.set(agent.id, {
        id: agent.id,
        name: agent.name,
        color: agent.chatColor,
        x,
        y,
        targetX: x,
        targetY: y,
        state: 'idle',
        animPhase: Math.random(), // fase inicial aleatória para dessincronizar animações
        speechBubble: null,
      });
    }
  }

  /**
   * Atualiza animPhase, interpola posição e expira speech bubbles.
   *
   * @param delta - Tempo em ms desde o último frame (tipicamente ~16ms)
   */
  update(delta: number): void {
    const now = Date.now();

    for (const state of this.states.values()) {
      // Avança fase de animação (ciclo completo em ~2.6s para idle)
      state.animPhase = (state.animPhase + delta / 2600) % 1;

      // Interpola posição durante movimento
      if (state.x !== state.targetX || state.y !== state.targetY) {
        const speed = 0.08; // fração por ms
        const dx = state.targetX - state.x;
        const dy = state.targetY - state.y;
        const dist = Math.sqrt(dx * dx + dy * dy);
        const step = speed * delta;

        if (dist <= step) {
          state.x = state.targetX;
          state.y = state.targetY;
          if (state.state === 'moving') {
            state.state = 'idle';
          }
        } else {
          state.x += (dx / dist) * step;
          state.y += (dy / dist) * step;
        }
      }

      // Expira speech bubbles
      if (state.speechBubble !== null && state.speechBubble.expiresAt <= now) {
        state.speechBubble = null;
      }
    }
  }

  /**
   * Retorna todos os estados de agente para o draw loop.
   */
  getAll(): AgentRenderState[] {
    return [...this.states.values()];
  }

  /**
   * Atualiza o estado de animação de um agente.
   *
   * @param id - ID do agente
   * @param state - Novo estado de animação
   */
  setState(id: string, state: AgentState): void {
    const agent = this.states.get(id);
    if (agent !== undefined) {
      agent.state = state;
    }
  }

  /**
   * Define o destino de movimento de um agente em pixels.
   *
   * @param id - ID do agente
   * @param tileX - Posição X destino em tiles
   * @param tileY - Posição Y destino em tiles
   */
  moveTo(id: string, tileX: number, tileY: number): void {
    const agent = this.states.get(id);
    if (agent !== undefined) {
      agent.targetX = tileX * TILE;
      agent.targetY = tileY * TILE;
      agent.state = 'moving';
    }
  }

  /**
   * Exibe um speech bubble sobre um agente por uma duração determinada.
   *
   * @param id - ID do agente
   * @param text - Texto do bubble (truncado em 40 chars se necessário)
   * @param durationMs - Duração em ms
   */
  showSpeech(id: string, text: string, durationMs: number): void {
    const agent = this.states.get(id);
    if (agent !== undefined) {
      const displayText = text.length > 40 ? `${text.slice(0, 37)}...` : text;
      const bubble: SpeechBubble = {
        text: displayText,
        expiresAt: Date.now() + durationMs,
      };
      agent.speechBubble = bubble;
    }
  }

  /**
   * Hit test — retorna id do agente clicado ou null.
   *
   * Bounding box: SPRITE_W × SPRITE_H centrado na posição do agente.
   *
   * @param px - Posição X do clique em pixels do canvas
   * @param py - Posição Y do clique em pixels do canvas
   */
  hitTest(px: number, py: number): string | null {
    for (const state of this.states.values()) {
      const left = state.x - SPRITE_W / 2;
      const top = state.y - SPRITE_H;
      const right = left + SPRITE_W;
      const bottom = top + SPRITE_H;

      if (px >= left && px <= right && py >= top && py <= bottom) {
        return state.id;
      }
    }
    return null;
  }
}
