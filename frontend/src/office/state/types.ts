/** Estado de animação de um agente no canvas */
export type AgentState = 'idle' | 'thinking' | 'working' | 'moving' | 'speaking';

/** Speech bubble exibida sobre um agente */
export interface SpeechBubble {
  text: string;
  /** Timestamp em ms (Date.now()) quando o bubble expira */
  expiresAt: number;
}

/**
 * Estado mutável de um agente para renderização no canvas.
 *
 * Mantido fora do React state — vive em AgentStateManager.
 * Atualizado pelo update() do game loop e por eventos Socket.io.
 */
export interface AgentRenderState {
  id: string;
  /** Posição X atual em pixels (interpolada durante movimento) */
  x: number;
  /** Posição Y atual em pixels */
  y: number;
  /** Destino X em pixels (igual a x quando parado) */
  targetX: number;
  /** Destino Y em pixels (igual a y quando parado) */
  targetY: number;
  state: AgentState;
  /** Fase da animação 0..1, avança com delta time */
  animPhase: number;
  /** Cor principal do agente (chatColor do protótipo) */
  color: string;
  /** Nome exibido no label */
  name: string;
  speechBubble: SpeechBubble | null;
}
