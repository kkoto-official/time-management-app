// tab-bar.jsx — bottom tab bar + tweaks panel

function TabBar({ current, goto, theme }) {
  const tabs = [
    { id: 'home',    label: 'ホーム',  icon: 'home' },
    { id: 'tracker', label: '計測',    icon: 'timer' },
    { id: 'report',  label: 'レポート', icon: 'chart' },
    { id: 'settings',label: '設定',    icon: 'gear' },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0, zIndex: 40,
      background: `linear-gradient(to top, ${theme.bg} 70%, ${theme.bg}00)`,
      paddingBottom: 28, paddingTop: 10,
    }}>
      <div style={{
        margin: '0 20px', height: 58, borderRadius: 22,
        background: theme.card, display: 'flex',
        boxShadow: '0 10px 30px rgba(42,30,20,0.08), 0 2px 4px rgba(42,30,20,0.04)',
        border: `1px solid ${theme.line}`,
      }}>
        {tabs.map(t => {
          const active = current === t.id || (current === 'detail' && t.id === 'home') || (current === 'create' && t.id === 'tracker');
          return (
            <button key={t.id} onClick={() => goto(t.id)} style={{
              flex: 1, border: 'none', background: 'transparent', cursor: 'pointer',
              display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
              gap: 2, color: active ? theme.accent : theme.inkMuted,
              fontFamily: 'inherit',
            }}>
              <Icon name={t.icon} size={22} color={active ? theme.accent : theme.inkMuted} stroke={active ? 2.2 : 1.8} />
              <span style={{ fontSize: 10, fontWeight: 700, letterSpacing: 0.3 }}>{t.label}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

// Tweaks panel
function TweaksPanel({ tweaks, setTweaks, onClose }) {
  const Section = ({ title, children }) => (
    <div style={{ marginBottom: 18 }}>
      <div style={{ fontSize: 10, letterSpacing: 1.2, color: '#999', fontWeight: 700, textTransform: 'uppercase', marginBottom: 8 }}>{title}</div>
      {children}
    </div>
  );
  const Pill = ({ active, label, onClick, swatch }) => (
    <button onClick={onClick} style={{
      padding: '7px 12px', borderRadius: 10, border: 'none', cursor: 'pointer',
      background: active ? '#1a1a1a' : '#f4f4f4', color: active ? '#fff' : '#333',
      fontSize: 12, fontWeight: 600, fontFamily: 'inherit',
      display: 'inline-flex', alignItems: 'center', gap: 6,
    }}>
      {swatch && <div style={{ width: 10, height: 10, borderRadius: 2, background: swatch }} />}
      {label}
    </button>
  );
  return (
    <div style={{
      position: 'fixed', right: 20, bottom: 20, width: 300, zIndex: 1000,
      background: '#fff', borderRadius: 18, padding: '14px 16px 16px',
      boxShadow: '0 20px 50px rgba(0,0,0,0.18), 0 0 0 1px rgba(0,0,0,0.05)',
      fontFamily: '-apple-system, system-ui', maxHeight: '80vh', overflowY: 'auto',
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
        <div style={{ fontSize: 14, fontWeight: 700, color: '#111' }}>Tweaks</div>
        <button onClick={onClose} style={{
          width: 24, height: 24, borderRadius: 6, border: 'none', background: '#f4f4f4', cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#666" strokeWidth="2.5" strokeLinecap="round"><path d="M6 6l12 12M6 18L18 6"/></svg>
        </button>
      </div>

      <Section title="Theme">
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          {['amber','terracotta','olive'].map(k => (
            <Pill key={k} active={tweaks.theme === k}
              label={k === 'amber' ? 'Amber' : k === 'terracotta' ? 'Terracotta' : 'Olive'}
              swatch={THEMES[k].accent}
              onClick={() => setTweaks({ theme: k })} />
          ))}
        </div>
      </Section>

      <Section title="Tracker grid">
        <div style={{ display: 'flex', gap: 6 }}>
          <Pill active={tweaks.cols === 2} label="2 columns" onClick={() => setTweaks({ cols: 2 })} />
          <Pill active={tweaks.cols === 3} label="3 columns" onClick={() => setTweaks({ cols: 3 })} />
        </div>
      </Section>

      <Section title="Home layout">
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          <Pill active={tweaks.homeLayout === 'donut'} label="Donut" onClick={() => setTweaks({ homeLayout: 'donut' })} />
          <Pill active={tweaks.homeLayout === 'timeline'} label="+ Timeline" onClick={() => setTweaks({ homeLayout: 'timeline' })} />
        </div>
      </Section>

      <Section title="Live tile effect">
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          <Pill active={tweaks.liveEffect === 'pulse'} label="Pulse" onClick={() => setTweaks({ liveEffect: 'pulse' })} />
          <Pill active={tweaks.liveEffect === 'glow'} label="Glow" onClick={() => setTweaks({ liveEffect: 'glow' })} />
          <Pill active={tweaks.liveEffect === 'plain'} label="Plain" onClick={() => setTweaks({ liveEffect: 'plain' })} />
        </div>
      </Section>
    </div>
  );
}

Object.assign(window, { TabBar, TweaksPanel });
