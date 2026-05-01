// design-system.jsx — warm palette, activity icons, helpers

const THEMES = {
  amber: {
    bg: '#fbf5ec',
    bgDeep: '#f4ead8',
    card: '#ffffff',
    ink: '#2a1e14',
    inkMuted: 'rgba(42,30,20,0.58)',
    inkSubtle: 'rgba(42,30,20,0.32)',
    line: 'rgba(42,30,20,0.09)',
    accent: '#c2410c',
    accentSoft: '#fde4cf',
  },
  terracotta: {
    bg: '#f7efe6',
    bgDeep: '#eedfce',
    card: '#ffffff',
    ink: '#3a2618',
    inkMuted: 'rgba(58,38,24,0.58)',
    inkSubtle: 'rgba(58,38,24,0.32)',
    line: 'rgba(58,38,24,0.10)',
    accent: '#b3541b',
    accentSoft: '#f8d9c0',
  },
  olive: {
    bg: '#f6f2e6',
    bgDeep: '#ece5d0',
    card: '#ffffff',
    ink: '#2e2a18',
    inkMuted: 'rgba(46,42,24,0.58)',
    inkSubtle: 'rgba(46,42,24,0.30)',
    line: 'rgba(46,42,24,0.09)',
    accent: '#7a6a1f',
    accentSoft: '#ebe1b8',
  },
};

// Activity palette — warm + muted
const ACTIVITIES = [
  { id: 'workA',   label: '仕事A',  color: '#b3541b', tint: '#f8d9c0', icon: 'briefcase' },
  { id: 'workB',   label: '仕事B',  color: '#8a6a2e', tint: '#efe1c3', icon: 'laptop'    },
  { id: 'game',    label: 'ゲーム', color: '#a04668', tint: '#f4d4de', icon: 'gamepad'   },
  { id: 'move',    label: '移動',   color: '#4a6b52', tint: '#d7e4d8', icon: 'train'     },
  { id: 'sleep',   label: '睡眠',   color: '#3d5a80', tint: '#d3ddea', icon: 'moon'      },
  { id: 'other',   label: 'その他', color: '#6b5a4b', tint: '#e2d8cd', icon: 'dots'      },
];

// Sample day data (minutes)
const TODAY_MIN = {
  workA: 218,  // 3h 38m
  workB: 74,   // 1h 14m
  game:  52,
  move:  43,
  sleep: 0,    // not yet tracked today
  other: 28,
};

const WEEK_DATA = [
  { d: '月', workA: 380, workB: 110, game: 30,  move: 80, sleep: 420, other: 40 },
  { d: '火', workA: 420, workB: 60,  game: 45,  move: 70, sleep: 440, other: 25 },
  { d: '水', workA: 360, workB: 140, game: 90,  move: 60, sleep: 390, other: 55 },
  { d: '木', workA: 400, workB: 90,  game: 20,  move: 85, sleep: 430, other: 30 },
  { d: '金', workA: 340, workB: 180, game: 120, move: 95, sleep: 400, other: 45 },
  { d: '土', workA: 90,  workB: 40,  game: 240, move: 60, sleep: 500, other: 80 },
  { d: '日', workA: 218, workB: 74,  game: 52,  move: 43, sleep: 0,   other: 28 },
];

const TIMELINE = [
  { start: '06:40', end: '07:12', act: 'other' },
  { start: '07:12', end: '07:48', act: 'move'  },
  { start: '07:48', end: '10:04', act: 'workA' },
  { start: '10:04', end: '10:20', act: 'other' },
  { start: '10:20', end: '12:02', act: 'workA' },
  { start: '12:02', end: '12:44', act: 'other' },
  { start: '12:44', end: '13:18', act: 'move'  },
  { start: '13:18', end: '14:36', act: 'workB' },
  { start: '14:36', end: '15:28', act: 'game'  },
  { start: '15:28', end: '16:22', act: 'workA' },
];

// ── Icons ───────────────────────────────────────────────
function Icon({ name, size = 28, color = 'currentColor', stroke = 1.8 }) {
  const common = {
    width: size, height: size, viewBox: '0 0 24 24',
    fill: 'none', stroke: color, strokeWidth: stroke,
    strokeLinecap: 'round', strokeLinejoin: 'round',
  };
  switch (name) {
    case 'briefcase': return (<svg {...common}><rect x="3" y="7" width="18" height="13" rx="2"/><path d="M9 7V5a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2"/><path d="M3 13h18"/></svg>);
    case 'laptop':    return (<svg {...common}><rect x="4" y="5" width="16" height="11" rx="1.5"/><path d="M2 19h20"/></svg>);
    case 'gamepad':   return (<svg {...common}><path d="M6 11h4M8 9v4"/><circle cx="15" cy="11" r="1"/><circle cx="17" cy="13" r="1"/><rect x="2" y="7" width="20" height="10" rx="5"/></svg>);
    case 'train':     return (<svg {...common}><rect x="5" y="3" width="14" height="14" rx="3"/><path d="M5 11h14"/><circle cx="9" cy="14" r="0.6" fill={color}/><circle cx="15" cy="14" r="0.6" fill={color}/><path d="M8 17l-2 4M16 17l2 4"/></svg>);
    case 'moon':      return (<svg {...common}><path d="M20 14a8 8 0 1 1-9.5-9.5A6 6 0 0 0 20 14z"/></svg>);
    case 'dots':      return (<svg {...common}><circle cx="6" cy="12" r="1.4" fill={color}/><circle cx="12" cy="12" r="1.4" fill={color}/><circle cx="18" cy="12" r="1.4" fill={color}/></svg>);
    case 'book':      return (<svg {...common}><path d="M4 4h6a3 3 0 0 1 3 3v13a2 2 0 0 0-2-2H4z"/><path d="M20 4h-6a3 3 0 0 0-3 3v13a2 2 0 0 1 2-2h7z"/></svg>);
    case 'coffee':    return (<svg {...common}><path d="M4 8h13v6a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4z"/><path d="M17 10h2a2 2 0 0 1 0 4h-2"/><path d="M7 3v2M10 3v2M13 3v2"/></svg>);
    case 'dumbbell':  return (<svg {...common}><path d="M3 10v4M6 7v10M18 7v10M21 10v4M6 12h12"/></svg>);
    case 'fork':      return (<svg {...common}><path d="M8 3v7a2 2 0 0 1-4 0V3M6 10v11"/><path d="M16 3s-2 3-2 7 2 4 2 4v7"/></svg>);

    case 'play':      return (<svg width={size} height={size} viewBox="0 0 24 24" fill={color}><path d="M7 4.5v15l13-7.5z"/></svg>);
    case 'pause':     return (<svg width={size} height={size} viewBox="0 0 24 24" fill={color}><rect x="6" y="4.5" width="4" height="15" rx="1"/><rect x="14" y="4.5" width="4" height="15" rx="1"/></svg>);
    case 'stop':      return (<svg width={size} height={size} viewBox="0 0 24 24" fill={color}><rect x="6" y="6" width="12" height="12" rx="1.5"/></svg>);
    case 'plus':      return (<svg {...common}><path d="M12 5v14M5 12h14"/></svg>);
    case 'chevron':   return (<svg {...common}><path d="M9 6l6 6-6 6"/></svg>);
    case 'chevronL':  return (<svg {...common}><path d="M15 6l-6 6 6 6"/></svg>);
    case 'check':     return (<svg {...common}><path d="M5 12l5 5L20 7"/></svg>);
    case 'close':     return (<svg {...common}><path d="M6 6l12 12M6 18L18 6"/></svg>);
    case 'edit':      return (<svg {...common}><path d="M4 20h4L20 8l-4-4L4 16z"/></svg>);
    case 'trash':     return (<svg {...common}><path d="M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13"/></svg>);
    case 'grid':      return (<svg {...common}><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></svg>);
    case 'list':      return (<svg {...common}><path d="M4 6h16M4 12h16M4 18h16"/></svg>);
    case 'chart':     return (<svg {...common}><path d="M4 20V10M10 20V4M16 20v-7M22 20H2"/></svg>);
    case 'home':      return (<svg {...common}><path d="M3 11l9-7 9 7v10a1 1 0 0 1-1 1h-5v-7H9v7H4a1 1 0 0 1-1-1z"/></svg>);
    case 'timer':     return (<svg {...common}><circle cx="12" cy="13" r="8"/><path d="M12 9v4l3 2M9 2h6"/></svg>);
    case 'gear':      return (<svg {...common}><circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M4.9 19.1L7 17M17 7l2.1-2.1"/></svg>);
    case 'drag':      return (<svg {...common}><circle cx="9" cy="6" r="1" fill={color}/><circle cx="15" cy="6" r="1" fill={color}/><circle cx="9" cy="12" r="1" fill={color}/><circle cx="15" cy="12" r="1" fill={color}/><circle cx="9" cy="18" r="1" fill={color}/><circle cx="15" cy="18" r="1" fill={color}/></svg>);
    case 'minus':     return (<svg {...common}><circle cx="12" cy="12" r="9" fill={color} stroke="none"/><path d="M7 12h10" stroke="#fff"/></svg>);
    case 'refresh':   return (<svg {...common}><path d="M21 12a9 9 0 1 1-3-6.7L21 8M21 3v5h-5"/></svg>);
    default: return null;
  }
}

// ── Helpers ─────────────────────────────────────────────
function fmtHM(min) {
  const h = Math.floor(min / 60);
  const m = Math.floor(min % 60);
  if (h === 0) return `${m}分`;
  if (m === 0) return `${h}時間`;
  return `${h}時間${m}分`;
}
function fmtHMshort(min) {
  const h = Math.floor(min / 60);
  const m = Math.floor(min % 60);
  if (h === 0) return `${m}m`;
  return `${h}h ${String(m).padStart(2,'0')}m`;
}
function fmtClock(sec) {
  const h = Math.floor(sec / 3600);
  const m = Math.floor((sec % 3600) / 60);
  const s = Math.floor(sec % 60);
  if (h > 0) return `${h}:${String(m).padStart(2,'0')}:${String(s).padStart(2,'0')}`;
  return `${String(m).padStart(2,'0')}:${String(s).padStart(2,'0')}`;
}
function getActivity(id) { return ACTIVITIES.find(a => a.id === id) || ACTIVITIES[5]; }

// Renders image if act.image is set, otherwise the symbol icon
function ActIcon({ act, size = 24, color = '#fff' }) {
  if (act && act.image) {
    return (
      <img src={act.image} alt="" style={{
        width: size * 1.4, height: size * 1.4, borderRadius: 8,
        objectFit: 'cover', display: 'block',
      }} />
    );
  }
  return <Icon name={act.icon} size={size} color={color} />;
}

Object.assign(window, {
  THEMES, ACTIVITIES, TODAY_MIN, WEEK_DATA, TIMELINE,
  Icon, ActIcon, fmtHM, fmtHMshort, fmtClock, getActivity,
});
