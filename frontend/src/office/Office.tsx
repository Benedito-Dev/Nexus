import { useCallback, useEffect, useRef, useState } from 'react';
import { OFFICE_H, OFFICE_W, SPRITE_H } from '../canvas/constants';
import { drawOffice } from '../canvas/draw';
import { startGameLoop } from '../canvas/loop';
import { AgentPopover } from './AgentPopover';
import { AGENTS, AGENTS_BY_ID } from './data/agents';
import { AgentStateManager } from './state/AgentStateManager';

interface OfficeProps {
  /** Callback invocado quando usuário clica "Falar com" no popover */
  onMention: (agentId: string) => void;
}

/**
 * Componente Office — wrapper React do canvas do escritório.
 *
 * Única integração entre React e Canvas API. O AgentStateManager é mantido
 * em useRef — nunca em useState — para evitar re-renders a 60fps.
 *
 * @param onMention - Callback que injeta @NomeAgente no input do chat
 */
export function Office({ onMention }: OfficeProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const managerRef = useRef<AgentStateManager>(new AgentStateManager());
  const [selectedAgentId, setSelectedAgentId] = useState<string | null>(null);
  const [selectedPos, setSelectedPos] = useState<{ x: number; y: number } | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (canvas === null) return;

    const ctx = canvas.getContext('2d');
    if (ctx === null) return;

    // OBRIGATÓRIO — sem interpolação em pixel art
    ctx.imageSmoothingEnabled = false;

    const manager = managerRef.current;
    manager.initialize(AGENTS);

    const cleanup = startGameLoop(
      ctx,
      (delta) => manager.update(delta),
      (renderCtx) => drawOffice(renderCtx, manager.getAll()),
    );

    return cleanup;
  }, []);

  const handleClick = useCallback((e: React.MouseEvent<HTMLCanvasElement>) => {
    const canvas = canvasRef.current;
    if (canvas === null) return;

    const rect = canvas.getBoundingClientRect();
    const px = e.clientX - rect.left;
    const py = e.clientY - rect.top;

    const agentId = managerRef.current.hitTest(px, py);

    if (agentId !== null) {
      // Obtém posição do agente para posicionar o popover
      const states = managerRef.current.getAll();
      const state = states.find((s) => s.id === agentId);
      if (state !== undefined) {
        setSelectedPos({ x: state.x, y: state.y - SPRITE_H });
      }
    } else {
      setSelectedPos(null);
    }
    setSelectedAgentId(agentId);
  }, []);

  const selectedAgent =
    selectedAgentId !== null ? (AGENTS_BY_ID.get(selectedAgentId) ?? null) : null;

  return (
    <div className="absolute inset-0">
      <canvas
        ref={canvasRef}
        width={OFFICE_W}
        height={OFFICE_H}
        onClick={handleClick}
        onKeyDown={(e) => {
          if (e.key === 'Escape') {
            setSelectedAgentId(null);
            setSelectedPos(null);
          }
        }}
        tabIndex={0}
        style={{
          imageRendering: 'pixelated',
          cursor: 'default',
          display: 'block',
          width: '100%',
          height: '100%',
        }}
        aria-label="Escritório Nexus — clique em um agente para interagir"
      />
      {selectedAgent !== null && selectedPos !== null && (
        <AgentPopover
          agent={selectedAgent}
          agentX={selectedPos.x}
          agentY={selectedPos.y}
          onClose={() => {
            setSelectedAgentId(null);
            setSelectedPos(null);
          }}
          onMention={onMention}
        />
      )}
    </div>
  );
}
