/**
 * Inicia o game loop do canvas com requestAnimationFrame e delta time.
 *
 * O loop chama update(delta) e draw(ctx) a cada frame.
 * Em dev, loga um aviso se o frame ultrapassar 12ms.
 *
 * @param ctx - Contexto 2D do canvas
 * @param update - Função chamada com delta em ms desde o último frame
 * @param draw - Função de renderização do frame
 * @returns Cleanup function — chamar no return do useEffect
 */
export function startGameLoop(
  ctx: CanvasRenderingContext2D,
  update: (delta: number) => void,
  draw: (ctx: CanvasRenderingContext2D) => void,
): () => void {
  let lastTime = 0;
  let rafId: number;

  function loop(timestamp: number) {
    const delta = lastTime === 0 ? 16 : timestamp - lastTime;
    lastTime = timestamp;

    ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);

    if (import.meta.env.DEV) {
      const start = performance.now();
      update(delta);
      draw(ctx);
      const elapsed = performance.now() - start;
      if (elapsed > 12) {
        console.warn(`[Nexus] Frame lento: ${elapsed.toFixed(1)}ms`);
      }
    } else {
      update(delta);
      draw(ctx);
    }

    rafId = requestAnimationFrame(loop);
  }

  rafId = requestAnimationFrame(loop);

  return () => cancelAnimationFrame(rafId);
}
