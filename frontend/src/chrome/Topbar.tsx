interface TopbarProps {
  connected: boolean;
  lastPong: number | null;
  onPing: () => void;
}

/**
 * Barra superior do Nexus.
 *
 * Exibe o brand, status da conexão WebSocket e botão de ping.
 *
 * @param connected - Se o socket está conectado ao backend
 * @param lastPong - Timestamp do último pong recebido (Date.now())
 * @param onPing - Callback para emitir evento ping
 */
export function Topbar({ connected, lastPong, onPing }: TopbarProps) {
  return (
    <header className="flex items-center gap-4 px-4 h-11 bg-[oklch(0.16_0.012_250)] border-b border-[oklch(0.27_0.012_250)] text-[13px] shrink-0">
      {/* Brand */}
      <div className="flex items-center gap-2 font-semibold tracking-tight">
        <div
          className="w-[18px] h-[18px] rounded-[3px] bg-[oklch(0.74_0.11_60)] relative"
          aria-hidden="true"
        />
        <span>Nexus</span>
      </div>

      {/* Project placeholder */}
      <span className="text-[oklch(0.62_0.008_250)]">
        <span className="text-[oklch(0.45_0.008_250)]">/</span>{' '}
        <strong className="text-[oklch(0.92_0.005_250)] font-medium">Sem projeto</strong>
      </span>

      {/* Spacer */}
      <div className="flex-1" />

      {/* Ping button */}
      <button
        type="button"
        onClick={onPing}
        disabled={!connected}
        className="text-[12px] px-3 py-1 rounded-[5px] border border-[oklch(0.27_0.012_250)] text-[oklch(0.62_0.008_250)] hover:text-[oklch(0.92_0.005_250)] disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
      >
        Ping
      </button>

      {/* Last pong indicator */}
      {lastPong !== null && (
        <span className="text-[11px] text-[oklch(0.45_0.008_250)] font-mono">
          pong {new Date(lastPong).toLocaleTimeString('pt-BR')}
        </span>
      )}

      {/* WS status */}
      <div className="flex items-center gap-1.5 text-[12px] text-[oklch(0.62_0.008_250)]">
        <span
          className={`w-[7px] h-[7px] rounded-full ${
            connected
              ? 'bg-[oklch(0.72_0.10_150)] shadow-[0_0_0_2px_oklch(0.72_0.10_150/0.18)]'
              : 'bg-[oklch(0.45_0.008_250)]'
          }`}
          aria-label={connected ? 'Conectado' : 'Desconectado'}
        />
        {connected ? 'Connected' : 'Disconnected'}
      </div>
    </header>
  );
}
