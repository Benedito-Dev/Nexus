import { io } from 'socket.io-client';
import type { Socket } from 'socket.io-client';

// Tipos temporários — substituir por @nexus/shared quando shared/ existir
// Fase 0: apenas ping/pong
interface ServerToClientEvents {
  pong: () => void;
}

interface ClientToServerEvents {
  ping: () => void;
}

/**
 * Tipo do socket tipado com o protocolo do Nexus.
 *
 * Fase 0: apenas ping/pong.
 * Fase 1+: importar ServerToClientEvents e ClientToServerEvents de @nexus/shared.
 */
export type NexusSocket = Socket<ServerToClientEvents, ClientToServerEvents>;

/**
 * Cria a conexão Socket.io com o backend do Nexus.
 *
 * Em dev, o Vite proxy redireciona /socket.io para localhost:3000.
 * Em prod, o frontend é servido do mesmo domínio — sem proxy necessário.
 *
 * @returns Socket tipado com eventos do protocolo Nexus
 */
export function createSocket(): NexusSocket {
  return io({ path: '/socket.io' }) as NexusSocket;
}
