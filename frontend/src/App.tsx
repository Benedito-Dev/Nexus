import { useCallback } from 'react';
import { Topbar } from './chrome/Topbar';
import { Office } from './office/Office';
import { useSocket } from './socket/hooks';

/**
 * Componente raiz do Nexus.
 *
 * Layout: topbar (44px) + área principal (flex: canvas + chat sidebar).
 * Socket criado aqui e propagado para Topbar e futuramente para ChatPanel.
 */
export function App() {
  const { socket, connected, lastPong } = useSocket();

  const handlePing = useCallback(() => {
    socket?.emit('ping');
  }, [socket]);

  const handleMention = useCallback((_agentId: string) => {
    // TODO Fase 1: injetar @NomeAgente no input do ChatPanel
  }, []);

  return (
    <div className="flex flex-col h-screen bg-[oklch(0.10_0.008_250)]">
      <Topbar connected={connected} lastPong={lastPong} onPing={handlePing} />

      <div className="flex flex-1 overflow-hidden min-h-0">
        {/* Área do canvas — escritório ocupa todo o espaço disponível */}
        <div className="flex-1 relative overflow-hidden bg-[oklch(0.12_0.010_245)]">
          <Office onMention={handleMention} />
        </div>

        {/* Chat sidebar placeholder — Fase 0 */}
        <aside className="w-80 border-l border-[oklch(0.27_0.012_250)] bg-[oklch(0.16_0.012_250)] flex flex-col shrink-0">
          <div className="px-4 py-3 border-b border-[oklch(0.27_0.012_250)]">
            <div className="text-[11px] uppercase tracking-[0.08em] text-[oklch(0.62_0.008_250)] font-semibold">
              Chat
            </div>
          </div>
          <div className="flex-1 flex items-center justify-center">
            <p className="text-[12px] text-[oklch(0.45_0.008_250)] text-center px-6">
              Chat disponivel na Fase 1.
            </p>
          </div>
        </aside>
      </div>
    </div>
  );
}
