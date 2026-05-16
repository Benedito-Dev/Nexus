/** Tamanho de 1 tile em pixels de tela */
export const TILE = 36;

/** Largura do escritório em tiles */
export const COLS = 32;

/** Altura do escritório em tiles */
export const ROWS = 18;

/** Largura total do canvas em pixels */
export const OFFICE_W = COLS * TILE; // 1152

/** Altura total do canvas em pixels */
export const OFFICE_H = ROWS * TILE; // 648

/** Tamanho de 1 pixel de sprite em pixels de tela */
export const PX = 2;

/** Largura do sprite em pixels de tela (12 * PX) */
export const SPRITE_W = 12 * PX; // 24

/** Altura do sprite em pixels de tela (18 * PX) */
export const SPRITE_H = 18 * PX; // 36

// Paleta de cores do escritório (derivada de nexus.css)
export const COLORS = {
  floor: 'oklch(0.33 0.020 60)',
  floor2: 'oklch(0.30 0.020 60)',
  floorLine: 'oklch(0.26 0.015 50)',
  wall: 'oklch(0.22 0.012 245)',
  wallTrim: 'oklch(0.30 0.014 245)',
  carpet: 'oklch(0.32 0.030 165)',
  carpet2: 'oklch(0.28 0.028 165)',
  notionFloor: 'oklch(0.38 0.018 80)',
  githubFloor: 'oklch(0.30 0.020 280)',
  desk: 'oklch(0.36 0.024 50)',
  deskDark: 'oklch(0.28 0.020 50)',
} as const;
