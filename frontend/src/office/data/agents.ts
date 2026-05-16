/** Paleta de cores do sprite de um agente */
export interface SpritePalette {
  skin: string;
  hair: string;
  shirt: string;
  pants: string;
  shoes: string;
}

/** Definição estática de um agente — dados do protótipo nexus-data.jsx */
export interface AgentDefinition {
  id: string;
  name: string;
  role: string;
  /** Posição home em tiles (x, y) */
  home: { x: number; y: number };
  /** Posição e tamanho da mesa em tiles */
  desk: { x: number; y: number; w: number; h: number };
  /** Cor de destaque no chat (oklch) */
  chatColor: string;
  /** Paleta de cores do sprite pixel art */
  sprite: SpritePalette;
  bio: string;
}

/**
 * Os 7 agentes do Nexus.
 *
 * Dados extraídos de nexus-data.jsx — posições em tiles (grid 32×18).
 */
export const AGENTS: AgentDefinition[] = [
  {
    id: 'marina',
    name: 'Marina',
    role: 'Director',
    home: { x: 16, y: 5 },
    desk: { x: 15, y: 3, w: 2, h: 1 },
    chatColor: 'oklch(0.78 0.10 35)',
    sprite: {
      skin: '#e8b896',
      hair: '#3a2a20',
      shirt: '#a8553a',
      pants: '#2a3340',
      shoes: '#1a1410',
    },
    bio: 'Leads. Listens first, decides last.',
  },
  {
    id: 'rafael',
    name: 'Rafael',
    role: 'Strategist',
    home: { x: 4, y: 8 },
    desk: { x: 3, y: 6, w: 2, h: 1 },
    chatColor: 'oklch(0.78 0.10 220)',
    sprite: {
      skin: '#d8a878',
      hair: '#2a2018',
      shirt: '#3a5878',
      pants: '#2a3340',
      shoes: '#1a1410',
    },
    bio: 'Plans. Maps unknowns into steps.',
  },
  {
    id: 'bruno',
    name: 'Bruno',
    role: 'Architect',
    home: { x: 4, y: 11 },
    desk: { x: 3, y: 9, w: 2, h: 1 },
    chatColor: 'oklch(0.78 0.10 280)',
    sprite: {
      skin: '#c89878',
      hair: '#1a1410',
      shirt: '#5848a0',
      pants: '#2a3340',
      shoes: '#1a1410',
    },
    bio: 'Picks the shape of the thing.',
  },
  {
    id: 'ana',
    name: 'Ana',
    role: 'Documenter',
    home: { x: 4, y: 14 },
    desk: { x: 3, y: 12, w: 2, h: 1 },
    chatColor: 'oklch(0.78 0.10 85)',
    sprite: {
      skin: '#f0c8a8',
      hair: '#7a4828',
      shirt: '#a08838',
      pants: '#2a3340',
      shoes: '#1a1410',
    },
    bio: 'Reads everything. Knows what we know.',
  },
  {
    id: 'lucas',
    name: 'Lucas',
    role: 'Implementer',
    home: { x: 28, y: 8 },
    desk: { x: 27, y: 6, w: 2, h: 1 },
    chatColor: 'oklch(0.78 0.10 145)',
    sprite: {
      skin: '#e8b896',
      hair: '#4a3020',
      shirt: '#3a8068',
      pants: '#2a3340',
      shoes: '#1a1410',
    },
    bio: 'Writes the code.',
  },
  {
    id: 'carla',
    name: 'Carla',
    role: 'Reviewer',
    home: { x: 28, y: 11 },
    desk: { x: 27, y: 9, w: 2, h: 1 },
    chatColor: 'oklch(0.78 0.10 0)',
    sprite: {
      skin: '#f0c8a8',
      hair: '#8a3838',
      shirt: '#a04848',
      pants: '#2a3340',
      shoes: '#1a1410',
    },
    bio: 'Catches what others missed.',
  },
  {
    id: 'diego',
    name: 'Diego',
    role: 'Designer',
    home: { x: 16, y: 15 },
    desk: { x: 15, y: 13, w: 2, h: 1 },
    chatColor: 'oklch(0.78 0.10 320)',
    sprite: {
      skin: '#d8a878',
      hair: '#2a2018',
      shirt: '#9a4880',
      pants: '#2a3340',
      shoes: '#1a1410',
    },
    bio: 'Owns the design system.',
  },
];

/** Lookup de agente por id — acesso O(1) */
export const AGENTS_BY_ID = new Map<string, AgentDefinition>(AGENTS.map((a) => [a.id, a]));
