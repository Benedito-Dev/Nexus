import { COLS, ROWS } from '../../canvas/constants';

/** Definição de uma sala especial no escritório */
export interface RoomDefinition {
  x: number;
  y: number;
  w: number;
  h: number;
  label: string;
  kind: 'notion' | 'github' | 'meeting';
}

/** Layout do escritório — grid e salas especiais */
export const OFFICE = {
  cols: COLS,
  rows: ROWS,
  rooms: {
    notion: { x: 0, y: 0, w: 7, h: 5, label: 'NOTION_DB', kind: 'notion' } satisfies RoomDefinition,
    github: {
      x: 25,
      y: 0,
      w: 7,
      h: 5,
      label: 'GITHUB_REPO',
      kind: 'github',
    } satisfies RoomDefinition,
    meeting: {
      x: 10,
      y: 7,
      w: 12,
      h: 6,
      label: 'MEETING_ROOM',
      kind: 'meeting',
    } satisfies RoomDefinition,
  },
} as const;
