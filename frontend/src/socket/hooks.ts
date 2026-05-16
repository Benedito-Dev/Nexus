import { useEffect, useRef, useState } from 'react';
import { createSocket } from './client';
import type { NexusSocket } from './client';

/**
 * Hook para gerenciar a conexão Socket.io com o backend do Nexus.
 *
 * Cria o socket uma vez, monitora conexão/desconexão e limpa no unmount.
 * O socket é estável entre renders — guardado em useRef.
 *
 * @returns { socket, connected, lastPong }
 */
export function useSocket(): {
  socket: NexusSocket | null;
  connected: boolean;
  lastPong: number | null;
} {
  const socketRef = useRef<NexusSocket | null>(null);
  const [connected, setConnected] = useState(false);
  const [lastPong, setLastPong] = useState<number | null>(null);

  useEffect(() => {
    const socket = createSocket();
    socketRef.current = socket;

    socket.on('connect', () => setConnected(true));
    socket.on('disconnect', () => setConnected(false));
    socket.on('pong', () => setLastPong(Date.now()));

    return () => {
      socket.disconnect();
      socketRef.current = null;
    };
  }, []);

  return { socket: socketRef.current, connected, lastPong };
}
