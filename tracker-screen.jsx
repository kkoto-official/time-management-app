// tracker-screen.jsx — widget grid of activity tiles + live timer bar + drag-reorder

function LiveTimerBar({ activeId, elapsed, paused, onPause, onStop, theme }) {
  if (!activeId) {
    return (
      <div style={{
        margin: '0 16px 16px', padding: '16px', borderRadius: 18,
        background: theme.card, border: `1.5px dashed ${theme.line}`,
        display: 'flex', alignItems: 'center', gap: 10,
      }}>
        <div style={{
          width: 36, height: 36, borderRadius: 10, background: theme.bgDeep,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name="timer" size={18} color={theme.inkMuted} />
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 14, fontWeight: 600, color: theme.ink }}>計測していません</div>
          <div style={{ fontSize: 12, color: theme.inkMuted, marginTop: 1 }}>
            下のタイルをタップして開始
          </div>
        </div>
      </div>
    );
  }
  const act = getActivity(activeId);
  return (
    <div style={{
      margin: '0 16px 16px', padding: '14px 16px', borderRadius: 20,
      background: act.color, color: '#fff', position: 'relative', overflow: 'hidden',
      boxShadow: `0 10px 30px ${act.color}55`,
    }}>
      <div style={{
        position: 'absolute', inset: 0,
        background: `radial-gradient(120% 80% at 100% 0%, rgba(255,255,255,0.2), transparent 60%)`,
      }} />
      <div style={{ position: 'relative', display: 'flex', alignItems: 'center', gap: 10, marginBottom: 6 }}>
        <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#fff',
          animation: paused ? 'none' : 'blink 1s ease-in-out infinite' }} />
        <span style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.2, textTransform: 'uppercase', opacity: 0.9 }}>
          {paused ? '一時停止中' : '計測中'}
        </span>
        <span style={{ fontSize: 11, fontWeight: 600, opacity: 0.7, marginLeft: 'auto' }}>
          開始 {new Date(Date.now() - elapsed*1000).toTimeString().slice(0,5)}
        </span>
      </div>
      <div style={{ position: 'relative', display: 'flex', alignItems: 'center', gap: 12 }}>
        <div style={{
          width: 44, height: 44, borderRadius: 12, background: 'rgba(255,255,255,0.22)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden',
        }}>
          <ActIcon act={act} size={22} color="#fff" />
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 16, fontWeight: 700 }}>{act.label}</div>
          <div style={{ fontSize: 32, fontWeight: 700, fontFeatureSettings: '"tnum"', letterSpacing: -1, marginTop: -2 }}>
            {fmtClock(elapsed)}
          </div>
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          <button onClick={onPause} style={{
            width: 42, height: 42, borderRadius: '50%',
            background: 'rgba(255,255,255,0.25)', border: 'none', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', padding: 0,
          }}>
            <Icon name={paused ? 'play' : 'pause'} size={16} color="#fff" />
          </button>
          <button onClick={onStop} style={{
            width: 42, height: 42, borderRadius: '50%',
            background: 'rgba(255,255,255,0.25)', border: 'none', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', padding: 0,
          }}>
            <Icon name="stop" size={16} color="#fff" />
          </button>
        </div>
      </div>
    </div>
  );
}

function ActivityTile({ act, isActive, elapsed, todayMin, cols, editing, onTap, onRemove, onEdit, theme,
  dragOver, onDragStart, onDragOver, onDragEnd, onDrop, idx }) {
  const size = cols === 3 ? 'sm' : 'lg';
  const h = size === 'sm' ? 108 : 150;
  return (
    <div
      draggable={editing}
      onDragStart={editing ? (e) => onDragStart(idx, e) : undefined}
      onDragOver={editing ? (e) => { e.preventDefault(); onDragOver(idx); } : undefined}
      onDragEnd={editing ? onDragEnd : undefined}
      onDrop={editing ? (e) => { e.preventDefault(); onDrop(idx); } : undefined}
      style={{ position: 'relative', animation: editing ? 'wiggle 0.35s ease-in-out infinite' : 'none' }}
    >
      <button onClick={() => editing ? onEdit() : onTap()} style={{
        position: 'relative', height: h, borderRadius: 22,
        background: isActive && !editing ? act.color : theme.card,
        color: isActive && !editing ? '#fff' : theme.ink,
        border: 'none', padding: size === 'sm' ? '12px' : '16px',
        display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
        cursor: editing ? 'grab' : 'pointer', fontFamily: 'inherit', textAlign: 'left', width: '100%',
        boxShadow: isActive && !editing
          ? `0 8px 24px ${act.color}55, inset 0 1px 0 rgba(255,255,255,0.18)`
          : '0 1px 2px rgba(0,0,0,0.03), 0 6px 20px rgba(42,30,20,0.04)',
        outline: dragOver ? `2px dashed ${theme.accent}` : 'none', outlineOffset: -4,
        transition: 'transform 0.15s ease, box-shadow 0.15s ease',
        animation: isActive && !editing ? 'tilePulse 2.5s ease-in-out infinite' : 'none',
        overflow: 'hidden',
      }}
      onMouseDown={e => { if (!editing) e.currentTarget.style.transform = 'scale(0.97)'; }}
      onMouseUp={e => e.currentTarget.style.transform = 'scale(1)'}
      onMouseLeave={e => e.currentTarget.style.transform = 'scale(1)'}
      >
        {isActive && !editing && (
          <div style={{
            position: 'absolute', inset: 0,
            background: `radial-gradient(120% 80% at 100% 0%, rgba(255,255,255,0.18), transparent 60%)`,
            pointerEvents: 'none',
          }} />
        )}

        <div style={{ position: 'relative', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <div style={{
            width: size === 'sm' ? 36 : 44, height: size === 'sm' ? 36 : 44,
            borderRadius: size === 'sm' ? 10 : 12,
            background: isActive && !editing ? 'rgba(255,255,255,0.22)' : act.tint,
            display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden',
          }}>
            <ActIcon act={act} size={size === 'sm' ? 20 : 24} color={isActive && !editing ? '#fff' : act.color} />
          </div>
          {editing && <Icon name="drag" size={16} color={theme.inkSubtle} />}
          {!editing && isActive && (
            <div style={{
              display: 'flex', alignItems: 'center', gap: 4,
              padding: '3px 7px', borderRadius: 6, background: 'rgba(255,255,255,0.22)',
              fontSize: 10, fontWeight: 700, letterSpacing: 0.8, textTransform: 'uppercase',
            }}>
              <div style={{ width: 5, height: 5, borderRadius: '50%', background: '#fff',
                animation: 'blink 1s ease-in-out infinite' }} />
              LIVE
            </div>
          )}
        </div>

        <div style={{ position: 'relative' }}>
          <div style={{
            fontSize: size === 'sm' ? 14 : 16, fontWeight: 700, letterSpacing: -0.3,
            color: isActive && !editing ? '#fff' : theme.ink,
          }}>{act.label}</div>
          <div style={{
            fontSize: size === 'sm' ? 12 : 13, fontWeight: 600, fontFeatureSettings: '"tnum"',
            color: isActive && !editing ? 'rgba(255,255,255,0.85)' : theme.inkMuted,
            marginTop: 2,
          }}>
            {editing ? 'タップで編集' : (isActive ? fmtClock(elapsed) : (todayMin > 0 ? `今日 ${fmtHMshort(todayMin)}` : '—'))}
          </div>
        </div>
      </button>

      {editing && (
        <div onClick={(e) => { e.stopPropagation(); onRemove(); }} style={{
          position: 'absolute', top: -6, left: -6, width: 24, height: 24,
          borderRadius: '50%', background: '#e11d48', color: '#fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 20, fontWeight: 700, lineHeight: 1, cursor: 'pointer',
          boxShadow: '0 2px 6px rgba(0,0,0,0.2)', zIndex: 3,
        }}>−</div>
      )}
    </div>
  );
}

function AddTile({ cols, theme, onTap }) {
  const h = cols === 3 ? 108 : 150;
  return (
    <button onClick={onTap} style={{
      height: h, borderRadius: 22, background: 'transparent',
      border: `1.5px dashed ${theme.line}`, color: theme.inkMuted,
      cursor: 'pointer', fontFamily: 'inherit', width: '100%',
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 6,
    }}>
      <Icon name="plus" size={22} color={theme.inkMuted} />
      <span style={{ fontSize: 12, fontWeight: 600 }}>追加</span>
    </button>
  );
}

function TrackerScreen({ theme, activities, setActivities, activeId, elapsed, paused, onTap, onPause, onStop, cols, setCols, goto, onEditActivity }) {
  const [editing, setEditing] = React.useState(false);
  const [dragFrom, setDragFrom] = React.useState(null);
  const [dragOver, setDragOver] = React.useState(null);

  const onDragStart = (i, e) => { setDragFrom(i); e.dataTransfer.effectAllowed = 'move'; };
  const onDragOver = (i) => { setDragOver(i); };
  const onDrop = (i) => {
    if (dragFrom == null || dragFrom === i) return;
    const next = [...activities];
    const [m] = next.splice(dragFrom, 1);
    next.splice(i, 0, m);
    setActivities(next);
    setDragFrom(null); setDragOver(null);
  };
  const onDragEnd = () => { setDragFrom(null); setDragOver(null); };

  return (
    <div style={{ padding: '0 0 120px', background: theme.bg, minHeight: '100%' }}>
      <div style={{ padding: '60px 20px 16px', display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
        <div>
          <div style={{ fontSize: 12, letterSpacing: 1.2, color: theme.inkMuted, fontWeight: 600, textTransform: 'uppercase' }}>
            Tracker
          </div>
          <div style={{ fontSize: 32, fontWeight: 700, color: theme.ink, letterSpacing: -0.8, marginTop: 2 }}>
            計測
          </div>
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          <div style={{
            display: 'inline-flex', padding: 3, borderRadius: 10,
            background: theme.bgDeep,
          }}>
            {[2,3].map(c => (
              <button key={c} onClick={() => setCols(c)} title={c === 2 ? '大' : '小'} style={{
                border: 'none', width: 36, height: 32, borderRadius: 7,
                background: cols === c ? theme.card : 'transparent',
                color: cols === c ? theme.ink : theme.inkMuted,
                cursor: 'pointer', fontFamily: 'inherit',
                boxShadow: cols === c ? '0 1px 2px rgba(0,0,0,0.08)' : 'none',
                display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 0,
              }}>
                {c === 2 ? (
                  <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
                    <rect x="2"  y="2"  width="6" height="6" rx="1.4" fill="currentColor"/>
                    <rect x="10" y="2"  width="6" height="6" rx="1.4" fill="currentColor"/>
                    <rect x="2"  y="10" width="6" height="6" rx="1.4" fill="currentColor"/>
                    <rect x="10" y="10" width="6" height="6" rx="1.4" fill="currentColor"/>
                  </svg>
                ) : (
                  <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
                    <rect x="2"   y="2"   width="3.6" height="3.6" rx="0.9" fill="currentColor"/>
                    <rect x="7.2" y="2"   width="3.6" height="3.6" rx="0.9" fill="currentColor"/>
                    <rect x="12.4" y="2"  width="3.6" height="3.6" rx="0.9" fill="currentColor"/>
                    <rect x="2"   y="7.2" width="3.6" height="3.6" rx="0.9" fill="currentColor"/>
                    <rect x="7.2" y="7.2" width="3.6" height="3.6" rx="0.9" fill="currentColor"/>
                    <rect x="12.4" y="7.2" width="3.6" height="3.6" rx="0.9" fill="currentColor"/>
                    <rect x="2"   y="12.4" width="3.6" height="3.6" rx="0.9" fill="currentColor"/>
                    <rect x="7.2" y="12.4" width="3.6" height="3.6" rx="0.9" fill="currentColor"/>
                    <rect x="12.4" y="12.4" width="3.6" height="3.6" rx="0.9" fill="currentColor"/>
                  </svg>
                )}
              </button>
            ))}
          </div>
          <button onClick={() => setEditing(!editing)} style={{
            height: 38, padding: '0 14px', borderRadius: 10,
            background: editing ? theme.ink : theme.card,
            color: editing ? theme.bg : theme.ink,
            border: editing ? 'none' : `1px solid ${theme.line}`,
            cursor: 'pointer', fontSize: 13, fontWeight: 600, fontFamily: 'inherit',
          }}>{editing ? '完了' : '編集'}</button>
        </div>
      </div>

      <LiveTimerBar activeId={activeId} elapsed={elapsed} paused={paused}
        onPause={onPause} onStop={onStop} theme={theme} />

      {!activeId && !editing && (
        <div style={{ margin: '0 20px 12px', fontSize: 12, color: theme.inkMuted }}>
          タイルをタップで計測開始・別タイルをタップで即切替
        </div>
      )}
      {editing && (
        <div style={{ margin: '0 20px 12px', fontSize: 12, color: theme.inkMuted }}>
          ドラッグで並び替え・タップで編集・−で削除
        </div>
      )}

      <div style={{
        padding: '0 16px', display: 'grid',
        gridTemplateColumns: `repeat(${cols}, 1fr)`, gap: 10,
      }}>
        {activities.map((id, idx) => {
          const act = getActivity(id);
          return (
            <ActivityTile key={id} act={act} idx={idx}
              isActive={activeId === id}
              elapsed={activeId === id ? elapsed : 0}
              todayMin={TODAY_MIN[id] || 0}
              cols={cols} editing={editing} theme={theme}
              dragOver={dragOver === idx && dragFrom !== idx}
              onTap={() => onTap(id)}
              onEdit={() => onEditActivity(id)}
              onRemove={() => setActivities(activities.filter(x => x !== id))}
              onDragStart={onDragStart} onDragOver={onDragOver}
              onDragEnd={onDragEnd} onDrop={onDrop}
            />
          );
        })}
        <AddTile cols={cols} theme={theme} onTap={() => goto('create')} />
      </div>

      <style>{`
        @keyframes blink { 0%,100% { opacity: 1; } 50% { opacity: 0.3; } }
        @keyframes tilePulse {
          0%, 100% { box-shadow: 0 8px 24px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.18); }
          50%      { box-shadow: 0 12px 32px rgba(0,0,0,0.25), inset 0 1px 0 rgba(255,255,255,0.18); }
        }
        @keyframes wiggle {
          0%,100% { transform: rotate(-0.6deg); }
          50%     { transform: rotate(0.6deg); }
        }
      `}</style>
    </div>
  );
}

Object.assign(window, { TrackerScreen, LiveTimerBar });
