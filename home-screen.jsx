// home-screen.jsx — today summary + donut + category breakdown

function DonutChart({ data, total, size = 220, thickness = 28, theme, centerLabel, centerValue }) {
  const cx = size / 2, cy = size / 2;
  const r = (size - thickness) / 2;
  const circ = 2 * Math.PI * r;
  let offset = 0;
  const segs = data.filter(d => d.value > 0);
  const sumVal = segs.reduce((s, d) => s + d.value, 0) || 1;

  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
        <circle cx={cx} cy={cy} r={r} fill="none" stroke={theme.bgDeep} strokeWidth={thickness} />
        {segs.map((d, i) => {
          const len = (d.value / sumVal) * circ;
          const gap = 2;
          const dash = `${Math.max(0, len - gap)} ${circ - Math.max(0, len - gap)}`;
          const dashoff = -offset;
          offset += len;
          return (
            <circle key={i} cx={cx} cy={cy} r={r} fill="none"
              stroke={d.color} strokeWidth={thickness}
              strokeDasharray={dash} strokeDashoffset={dashoff}
              strokeLinecap="butt" />
          );
        })}
      </svg>
      <div style={{
        position: 'absolute', inset: 0, display: 'flex',
        flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      }}>
        <div style={{ fontSize: 12, letterSpacing: 1.5, color: theme.inkMuted, textTransform: 'uppercase', fontWeight: 600 }}>
          {centerLabel}
        </div>
        <div style={{ fontSize: 40, fontWeight: 700, color: theme.ink, letterSpacing: -1, marginTop: 2, fontFeatureSettings: '"tnum"' }}>
          {centerValue}
        </div>
      </div>
    </div>
  );
}

function PeriodTabs({ value, onChange, theme }) {
  const tabs = [['day','日'],['week','週'],['month','月']];
  return (
    <div style={{
      display: 'inline-flex', padding: 3, borderRadius: 12,
      background: theme.bgDeep, gap: 2,
    }}>
      {tabs.map(([k, label]) => {
        const active = value === k;
        return (
          <button key={k} onClick={() => onChange(k)} style={{
            border: 'none', padding: '6px 18px', borderRadius: 9,
            fontSize: 14, fontWeight: 600, cursor: 'pointer',
            background: active ? theme.card : 'transparent',
            color: active ? theme.ink : theme.inkMuted,
            boxShadow: active ? '0 1px 2px rgba(0,0,0,0.08)' : 'none',
            fontFamily: 'inherit',
          }}>{label}</button>
        );
      })}
    </div>
  );
}

function CategoryRow({ act, minutes, total, theme, onClick }) {
  const pct = total ? (minutes / total) * 100 : 0;
  return (
    <button onClick={onClick} style={{
      width: '100%', display: 'flex', alignItems: 'center', gap: 12,
      padding: '12px 0', background: 'transparent', border: 'none',
      borderBottom: `1px solid ${theme.line}`, cursor: 'pointer',
      fontFamily: 'inherit', textAlign: 'left',
    }}>
      <div style={{
        width: 38, height: 38, borderRadius: 10, background: act.tint,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: act.color, flexShrink: 0,
      }}>
        <ActIcon act={act} size={20} color={act.color} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
          <span style={{ fontSize: 15, fontWeight: 600, color: theme.ink }}>{act.label}</span>
          <span style={{ fontSize: 15, fontWeight: 600, color: theme.ink, fontFeatureSettings: '"tnum"' }}>{fmtHMshort(minutes)}</span>
        </div>
        <div style={{ marginTop: 6, height: 4, borderRadius: 2, background: theme.bgDeep, overflow: 'hidden' }}>
          <div style={{ width: `${pct}%`, height: '100%', background: act.color, borderRadius: 2 }} />
        </div>
      </div>
    </button>
  );
}

function LiveBar({ activeId, elapsed, theme, onTap, onPause, paused }) {
  if (!activeId) return null;
  const act = getActivity(activeId);
  return (
    <div onClick={onTap} style={{
      margin: '0 16px 10px', padding: '10px 12px', borderRadius: 18,
      background: act.color, color: '#fff', display: 'flex', alignItems: 'center', gap: 10,
      boxShadow: `0 6px 20px ${act.color}40`, cursor: 'pointer',
      position: 'relative', overflow: 'hidden',
    }}>
      <div style={{
        position: 'absolute', inset: 0, background: 'rgba(255,255,255,0.08)',
        animation: paused ? 'none' : 'pulse 2s ease-in-out infinite',
      }} />
      <div style={{ position: 'relative', width: 34, height: 34, borderRadius: 10,
        background: 'rgba(255,255,255,0.22)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <ActIcon act={act} size={18} color="#fff" />
      </div>
      <div style={{ position: 'relative', flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: 0.8, opacity: 0.85, textTransform: 'uppercase' }}>
          {paused ? '一時停止中' : '計測中'}
        </div>
        <div style={{ fontSize: 15, fontWeight: 700, marginTop: 1 }}>{act.label}</div>
      </div>
      <div style={{ position: 'relative', fontSize: 22, fontWeight: 700, fontFeatureSettings: '"tnum"', letterSpacing: -0.5 }}>
        {fmtClock(elapsed)}
      </div>
      <button onClick={(e) => { e.stopPropagation(); onPause(); }} style={{
        position: 'relative', width: 34, height: 34, borderRadius: '50%',
        background: 'rgba(255,255,255,0.25)', border: 'none', cursor: 'pointer',
        display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', padding: 0,
      }}>
        <Icon name={paused ? 'play' : 'pause'} size={14} color="#fff" />
      </button>
    </div>
  );
}

function HomeScreen({ theme, period, setPeriod, onSelectActivity, activeId, elapsed, paused, onPause, goto, homeLayout }) {
  const data = period === 'day'
    ? Object.entries(TODAY_MIN).map(([id, v]) => ({ id, value: v, color: getActivity(id).color }))
    : (() => {
        const agg = {};
        WEEK_DATA.forEach(d => Object.entries(d).forEach(([k, v]) => { if (k !== 'd') agg[k] = (agg[k]||0) + v; }));
        return Object.entries(agg).map(([id, v]) => ({ id, value: v, color: getActivity(id).color }));
      })();
  const total = data.reduce((s, d) => s + d.value, 0);
  const tracked = period === 'day'
    ? total - (TODAY_MIN.sleep || 0) // exclude sleep when 0
    : total;

  return (
    <div style={{ padding: '0 0 120px', background: theme.bg, minHeight: '100%' }}>
      {/* Header */}
      <div style={{ padding: '60px 20px 14px', display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
        <div>
          <div style={{ fontSize: 12, letterSpacing: 1.2, color: theme.inkMuted, fontWeight: 600, textTransform: 'uppercase' }}>
            2026年4月20日 月曜
          </div>
          <div style={{ fontSize: 32, fontWeight: 700, color: theme.ink, letterSpacing: -0.8, marginTop: 2 }}>
            今日の記録
          </div>
        </div>
        <button onClick={() => goto('settings')} style={{
          width: 38, height: 38, borderRadius: 10, background: theme.card,
          border: `1px solid ${theme.line}`, cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name="gear" size={18} color={theme.ink} />
        </button>
      </div>

      {/* Live bar */}
      <LiveBar activeId={activeId} elapsed={elapsed} paused={paused} theme={theme}
        onTap={() => goto('tracker')} onPause={onPause} />

      {/* Period tabs */}
      <div style={{ padding: '4px 20px 16px' }}>
        <PeriodTabs value={period} onChange={setPeriod} theme={theme} />
      </div>

      {/* Donut card */}
      <div style={{
        margin: '0 16px', padding: '24px 20px', borderRadius: 24,
        background: theme.card, display: 'flex', alignItems: 'center', gap: 18,
        boxShadow: '0 1px 2px rgba(0,0,0,0.03), 0 10px 30px rgba(42,30,20,0.05)',
      }}>
        <DonutChart
          data={data}
          total={total}
          theme={theme}
          size={160}
          thickness={22}
          centerLabel={period === 'day' ? '記録' : period === 'week' ? '今週' : '今月'}
          centerValue={fmtHMshort(tracked)}
        />
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 10 }}>
          {data.filter(d => d.value > 0).slice(0, 4).map(d => {
            const act = getActivity(d.id);
            return (
              <div key={d.id} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <div style={{ width: 8, height: 8, borderRadius: 2, background: d.color }} />
                <span style={{ fontSize: 13, color: theme.ink, flex: 1, fontWeight: 500 }}>{act.label}</span>
                <span style={{ fontSize: 12, color: theme.inkMuted, fontFeatureSettings: '"tnum"', fontWeight: 600 }}>
                  {Math.round((d.value/total)*100)}%
                </span>
              </div>
            );
          })}
        </div>
      </div>

      {/* Category breakdown */}
      <div style={{ padding: '24px 20px 8px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ fontSize: 13, fontWeight: 700, color: theme.ink, letterSpacing: 0.6, textTransform: 'uppercase' }}>
          カテゴリ別
        </div>
        <button onClick={() => goto('report')} style={{
          border: 'none', background: 'transparent', color: theme.accent,
          fontSize: 13, fontWeight: 600, cursor: 'pointer', padding: 0, fontFamily: 'inherit',
        }}>詳細レポート →</button>
      </div>
      <div style={{ margin: '0 16px', padding: '4px 16px 8px', borderRadius: 20, background: theme.card }}>
        {data.filter(d => d.value > 0).sort((a,b)=>b.value-a.value).map(d => (
          <CategoryRow key={d.id} act={getActivity(d.id)} minutes={d.value}
            total={total} theme={theme} onClick={() => onSelectActivity(d.id)} />
        ))}
      </div>

      {/* Quick shortcut */}
      <div style={{ padding: '16px 20px 0' }}>
        <button onClick={() => goto('tracker')} style={{
          width: '100%', padding: '14px', borderRadius: 16,
          background: theme.ink, color: theme.bg, border: 'none',
          fontSize: 15, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        }}>
          <Icon name="timer" size={18} color={theme.bg} />
          アクティビティを計測
        </button>
      </div>

      <style>{`@keyframes pulse { 0%,100% { opacity: 0.3; } 50% { opacity: 0.7; } }`}</style>
    </div>
  );
}

Object.assign(window, { HomeScreen, DonutChart, PeriodTabs });
