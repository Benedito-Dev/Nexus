import type { AgentDefinition } from './data/agents';

interface AgentPopoverProps {
  agent: AgentDefinition;
  /** Posição X do agente em pixels do canvas (para posicionar o popover) */
  agentX: number;
  /** Posição Y do agente em pixels do canvas (topo do sprite) */
  agentY: number;
  onClose: () => void;
  onMention: (agentId: string) => void;
}

/**
 * Popover exibido ao clicar em um agente no Canvas.
 *
 * Div posicionada absolutamente sobre o canvas com z-index acima.
 * Posição calculada a partir das coordenadas do agente em pixels.
 *
 * @param agent - Dados do agente clicado
 * @param agentX - Posição X do agente em pixels do canvas
 * @param agentY - Posição Y do topo do sprite em pixels do canvas
 * @param onClose - Fecha o popover
 * @param onMention - Callback que injeta @NomeAgente no input do chat
 */
export function AgentPopover({ agent, agentX, agentY, onClose, onMention }: AgentPopoverProps) {
  return (
    <>
      {/* Overlay invisível para fechar ao clicar ou pressionar Esc */}
      <div
        className="absolute inset-0"
        style={{ zIndex: 49 }}
        role="button"
        tabIndex={-1}
        aria-label="Fechar popover"
        onClick={onClose}
        onKeyDown={(e) => {
          if (e.key === 'Escape' || e.key === 'Enter') onClose();
        }}
      />

      {/* Popover posicionado acima do agente */}
      <div
        className="absolute w-[260px] rounded-[10px] border border-[oklch(0.27_0.012_250)] bg-[oklch(0.16_0.012_250)] p-[14px] shadow-[0_18px_40px_rgba(0,0,0,0.55)]"
        style={{
          left: agentX - 130,
          top: agentY - 10,
          transform: 'translateY(-100%)',
          zIndex: 50,
          pointerEvents: 'auto',
        }}
      >
        {/* Setinha */}
        <div className="absolute left-1/2 -translate-x-1/2 -bottom-[6px] w-[10px] h-[10px] rotate-45 bg-[oklch(0.16_0.012_250)] border-r border-b border-[oklch(0.27_0.012_250)]" />

        {/* Cabeçalho */}
        <div className="flex items-center gap-2.5 mb-2.5">
          {/* Avatar — retângulo com cor do agente (Fase 0) */}
          <div
            className="w-10 h-10 rounded-[7px] border border-[oklch(0.27_0.012_250)] shrink-0"
            style={{ background: agent.chatColor }}
            aria-label={`Avatar de ${agent.name}`}
          />
          <div>
            <div className="font-semibold text-[14px] tracking-tight">{agent.name}</div>
            <div className="text-[11px] uppercase tracking-[0.06em] text-[oklch(0.62_0.008_250)]">
              {agent.role}
            </div>
          </div>
        </div>

        {/* Bio */}
        <div className="text-[12px] text-[oklch(0.62_0.008_250)] bg-[oklch(0.20_0.014_250)] border border-[oklch(0.27_0.012_250)] rounded-[7px] px-2.5 py-2 mb-2.5 leading-[1.4]">
          {agent.bio}
        </div>

        {/* Botão Falar */}
        <button
          type="button"
          onClick={() => {
            onMention(agent.id);
            onClose();
          }}
          className="w-full bg-[oklch(0.74_0.11_60)] text-[oklch(0.18_0.008_250)] font-semibold text-[13px] py-2 px-3 rounded-[7px] border-0 cursor-pointer hover:bg-[oklch(0.78_0.12_60)] active:translate-y-[1px] transition-colors"
        >
          Falar com {agent.name}
        </button>
      </div>
    </>
  );
}
