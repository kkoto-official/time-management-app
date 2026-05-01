// detail-screens.jsx — activity detail + create + report + settings + timeline

function ActivityDetail({ theme, activityId, goto }) {
  const act = getActivity(activityId);
  const todayMin = TODAY_MIN[activityId] || 0;
  const weekMin = WEEK_DATA.reduce((s, d) => s + (d[activityId] || 0), 0);
  const maxW = Math.max(...WEEK_DATA.map(d => d[activityId] || 0), 60);

  return (
    <div style={{ padding: '0 0 120px', background: theme.bg, minHeight: '100%' }}>
      <div style={{ padding: '60px 20px 16px', display: 'flex', alignItems: 'center', gap: 12 }}>
        <button onClick={() => goto('home')} style={{
          width: 38, height: 38, borderRadius: 10, background: theme.card,
          border: `1px solid ${theme.line}`, cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name="chevronL" size={18} color={theme.ink} />
        </button>
        <div style={{ flex: 1 }} />
        <button style={{
          width: 38, height: 38, borderRadius: 10, background: theme.card,
          border: `1px solid ${theme.line}`, cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name="edit" size={16} color={theme.ink} />
        </button>
      </div>

      {/* Hero */}
      <div style={{ padding: '0 20px 20px' }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 14, marginBottom: 14,
        }}>
          <div style={{
            width: 56, height: 56, borderRadius: 16, background: act.tint,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <ActIcon act={act} size={28} color={act.color} />
          </div>
          <div>
            <div style={{ fontSize: 12, letterSpacing: 1.2, color: theme.inkMuted, fontWeight: 600, textTransform: 'uppercase' }}>Activity</div>
            <div style={{ fontSize: 28, fontWeight: 700, color: theme.ink, letterSpacing: -0.5 }}>{act.label}</div>
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          <StatCard theme={theme} label="今日" value={fmtHMshort(todayMin)} sub="4セッション" accent={act.color} />
          <StatCard theme={theme} label="今週" value={fmtHMshort(weekMin)} sub={`1日平均 ${fmtHMshort(weekMin/7)}`} />
        </div>
      </div>

      {/* Weekly chart */}
      <div style={{
        margin: '0 16px 16px', padding: '20px', borderRadius: 24,
        background: theme.card, boxShadow: '0 1px 2px rgba(0,0,0,0.03)',
      }}>
        <div style={{ fontSize: 13, fontWeight: 700, color: theme.ink, letterSpacing: 0.5, textTransform: 'uppercase', marginBottom: 14 }}>
          週の推移
        </div>
        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 6, height: 140 }}>
          {WEEK_DATA.map((d, i) => {
            const v = d[activityId] || 0;
            const h = (v / maxW) * 120;
            const isToday = i === 6;
            return (
              <div key={d.d} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
                <div style={{ fontSize: 10, fontWeight: 600, color: theme.inkMuted, fontFeatureSettings: '"tnum"' }}>
                  {v > 0 ? Math.round(v/60*10)/10 + 'h' : ''}
                </div>
                <div style={{
                  width: '100%', height: h, borderRadius: 6,
                  background: isToday ? act.color : act.tint,
                  minHeight: 4,
                }} />
                <div style={{ fontSize: 11, color: isToday ? act.color : theme.inkMuted, fontWeight: isToday ? 700 : 500 }}>
                  {d.d}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Recent sessions */}
      <div style={{ padding: '4px 20px 8px', fontSize: 13, fontWeight: 700, color: theme.ink, letterSpacing: 0.5, textTransform: 'uppercase' }}>
        今日のセッション
      </div>
      <div style={{ margin: '0 16px', padding: '4px 16px', borderRadius: 20, background: theme.card }}>
        {[
          { s: '07:48', e: '10:04', dur: 136 },
          { s: '10:20', e: '12:02', dur: 102 },
          { s: '15:28', e: '16:22', dur: 54 },
        ].map((sess, i, arr) => (
          <div key={i} style={{
            display: 'flex', alignItems: 'center', padding: '14px 0',
            borderBottom: i < arr.length - 1 ? `1px solid ${theme.line}` : 'none',
          }}>
            <div style={{ fontSize: 15, color: theme.ink, fontFeatureSettings: '"tnum"', fontWeight: 600, width: 120 }}>
              {sess.s} – {sess.e}
            </div>
            <div style={{ flex: 1, fontSize: 14, color: theme.inkMuted }}>
              {i === 0 ? '朝のフォーカス' : i === 1 ? '午前の続き' : '午後の作業'}
            </div>
            <div style={{ fontSize: 15, fontWeight: 700, color: act.color, fontFeatureSettings: '"tnum"' }}>
              {fmtHMshort(sess.dur)}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function StatCard({ theme, label, value, sub, accent }) {
  return (
    <div style={{
      padding: '16px', borderRadius: 18, background: theme.card,
      boxShadow: '0 1px 2px rgba(0,0,0,0.03)',
    }}>
      <div style={{ fontSize: 11, letterSpacing: 1, color: theme.inkMuted, fontWeight: 700, textTransform: 'uppercase' }}>{label}</div>
      <div style={{ fontSize: 24, fontWeight: 700, color: accent || theme.ink, letterSpacing: -0.5, fontFeatureSettings: '"tnum"', marginTop: 4 }}>{value}</div>
      <div style={{ fontSize: 12, color: theme.inkMuted, marginTop: 2 }}>{sub}</div>
    </div>
  );
}

// ── Create activity ────────────────────────────────────────
const ICON_CHOICES = ['briefcase','laptop','gamepad','train','moon','book','coffee','dumbbell','fork','dots'];
const COLOR_CHOICES = ['#b3541b','#c2410c','#8a6a2e','#7a6a1f','#a04668','#4a6b52','#3d5a80','#6b5a4b','#a0522d','#9a3f3f'];

function CreateScreen({ theme, goto, onCreate, onUpdate, onDelete, editing: editingAct }) {
  const isEdit = !!editingAct;
  const [name, setName] = React.useState(isEdit ? editingAct.label : '読書');
  const [icon, setIcon] = React.useState(isEdit ? editingAct.icon : 'book');
  const [image, setImage] = React.useState(isEdit ? (editingAct.image || null) : null);
  const [color, setColor] = React.useState(isEdit ? editingAct.color : '#a0522d');
  const [customOpen, setCustomOpen] = React.useState(false);
  const fileRef = React.useRef(null);

  const onPickFile = (e) => {
    const f = e.target.files && e.target.files[0];
    if (!f) return;
    const reader = new FileReader();
    reader.onload = () => { setImage(reader.result); };
    reader.readAsDataURL(f);
  };

  const previewIconEl = image
    ? <img src={image} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', borderRadius: 28 }} />
    : <Icon name={icon} size={46} color="#fff" />;

  const handleSave = () => {
    if (isEdit) { onUpdate(editingAct.id, { label: name, icon, image, color }); goto('tracker'); }
    else { onCreate({ name, icon, image, color }); goto('tracker'); }
  };

  return (
    <div style={{ padding: '0 0 120px', background: theme.bg, minHeight: '100%' }}>
      <div style={{ padding: '60px 20px 16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={() => goto('tracker')} style={{
          border: 'none', background: 'transparent', color: theme.inkMuted,
          fontSize: 15, fontWeight: 500, cursor: 'pointer', fontFamily: 'inherit', padding: 0,
        }}>キャンセル</button>
        <div style={{ fontSize: 16, fontWeight: 700, color: theme.ink }}>{isEdit ? 'アクティビティ編集' : '新規アクティビティ'}</div>
        <button onClick={handleSave} style={{
          border: 'none', background: 'transparent', color: theme.accent,
          fontSize: 15, fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit', padding: 0,
        }}>{isEdit ? '保存' : '追加'}</button>
      </div>

      {/* preview */}
      <div style={{ padding: '20px 20px 24px', display: 'flex', justifyContent: 'center' }}>
        <div style={{
          width: 110, height: 110, borderRadius: 28, background: image ? '#000' : color,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: `0 12px 30px ${color}55`, overflow: 'hidden', position: 'relative',
        }}>
          {previewIconEl}
          {image && (
            <div style={{
              position: 'absolute', inset: 0, borderRadius: 28,
              boxShadow: `inset 0 0 0 3px ${color}`,
            }} />
          )}
        </div>
      </div>

      {/* name */}
      <div style={{ margin: '0 16px 16px', padding: '14px 16px', borderRadius: 16, background: theme.card }}>
        <div style={{ fontSize: 11, letterSpacing: 1, color: theme.inkMuted, fontWeight: 700, textTransform: 'uppercase' }}>名前</div>
        <input value={name} onChange={e => setName(e.target.value)} style={{
          width: '100%', border: 'none', background: 'transparent', outline: 'none',
          fontSize: 18, fontWeight: 600, color: theme.ink, marginTop: 6, fontFamily: 'inherit',
        }} />
      </div>

      {/* icon */}
      <div style={{ padding: '4px 20px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ fontSize: 11, letterSpacing: 1, color: theme.inkMuted, fontWeight: 700, textTransform: 'uppercase' }}>アイコン</div>
        {image && (
          <button onClick={() => setImage(null)} style={{
            border: 'none', background: 'transparent', color: theme.accent,
            fontSize: 12, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit', padding: 0,
          }}>画像を外す</button>
        )}
      </div>
      <div style={{ margin: '0 16px 16px', padding: '12px', borderRadius: 16, background: theme.card }}>
        {/* image upload tile */}
        <input ref={fileRef} type="file" accept="image/*" onChange={onPickFile} style={{ display: 'none' }} />
        <button onClick={() => fileRef.current && fileRef.current.click()} style={{
          width: '100%', padding: '12px', borderRadius: 12, border: `1.5px dashed ${image ? color : theme.line}`,
          background: image ? color + '12' : theme.bgDeep,
          cursor: 'pointer', fontFamily: 'inherit', color: theme.ink,
          display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10,
        }}>
          <div style={{
            width: 40, height: 40, borderRadius: 10, background: image ? 'transparent' : theme.card,
            border: image ? 'none' : `1px solid ${theme.line}`, overflow: 'hidden',
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
          }}>
            {image
              ? <img src={image} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
              : <Icon name="plus" size={18} color={theme.inkMuted} />
            }
          </div>
          <div style={{ flex: 1, textAlign: 'left' }}>
            <div style={{ fontSize: 14, fontWeight: 600, color: theme.ink }}>
              {image ? '画像を変更' : '画像を選択'}
            </div>
            <div style={{ fontSize: 11, color: theme.inkMuted, marginTop: 2 }}>
              PNG / JPG · 正方形推奨
            </div>
          </div>
        </button>

        {/* divider */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, margin: '4px 0 10px' }}>
          <div style={{ flex: 1, height: 1, background: theme.line }} />
          <div style={{ fontSize: 10, fontWeight: 700, color: theme.inkMuted, letterSpacing: 1 }}>または</div>
          <div style={{ flex: 1, height: 1, background: theme.line }} />
        </div>

        {/* symbol grid */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 8 }}>
          {ICON_CHOICES.map(i => (
            <button key={i} onClick={() => { setIcon(i); setImage(null); }} style={{
              aspectRatio: '1', borderRadius: 12, border: 'none', cursor: 'pointer',
              background: (!image && icon === i) ? color + '22' : theme.bgDeep,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              outline: (!image && icon === i) ? `2px solid ${color}` : 'none',
            }}>
              <Icon name={i} size={22} color={(!image && icon === i) ? color : theme.ink} />
            </button>
          ))}
        </div>
      </div>

      {/* color */}
      <div style={{ padding: '4px 20px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ fontSize: 11, letterSpacing: 1, color: theme.inkMuted, fontWeight: 700, textTransform: 'uppercase' }}>カラー</div>
        <button onClick={() => setCustomOpen(!customOpen)} style={{
          border: 'none', background: 'transparent', color: theme.accent,
          fontSize: 12, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit', padding: 0,
        }}>{customOpen ? '閉じる' : 'その他…'}</button>
      </div>
      <div style={{ margin: '0 16px', padding: '14px', borderRadius: 16, background: theme.card }}>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', justifyContent: 'center' }}>
          {COLOR_CHOICES.map(c => (
            <button key={c} onClick={() => setColor(c)} style={{
              width: 38, height: 38, borderRadius: '50%', background: c,
              border: color === c ? `3px solid ${theme.ink}` : 'none',
              outline: color === c ? `2px solid ${theme.bg}` : 'none',
              outlineOffset: -5, cursor: 'pointer',
            }} />
          ))}
          {/* custom color trigger as a color wheel */}
          <button onClick={() => setCustomOpen(true)} title="カスタムカラー" style={{
            width: 38, height: 38, borderRadius: '50%', cursor: 'pointer',
            background: 'conic-gradient(from 0deg, #ff3b30, #ff9500, #ffcc00, #34c759, #00c7be, #5ac8fa, #007aff, #5856d6, #af52de, #ff2d55, #ff3b30)',
            border: !COLOR_CHOICES.includes(color) ? `3px solid ${theme.ink}` : `1px solid ${theme.line}`,
            outline: !COLOR_CHOICES.includes(color) ? `2px solid ${theme.bg}` : 'none',
            outlineOffset: -5,
          }} />
        </div>

        {customOpen && (
          <div style={{
            marginTop: 14, paddingTop: 14, borderTop: `1px solid ${theme.line}`,
            display: 'flex', flexDirection: 'column', gap: 10,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <input type="color" value={color} onChange={e => setColor(e.target.value)}
                style={{
                  width: 56, height: 56, border: 'none', borderRadius: 14,
                  background: 'transparent', cursor: 'pointer', padding: 0,
                }} />
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 11, letterSpacing: 1, color: theme.inkMuted, fontWeight: 700, textTransform: 'uppercase' }}>HEX</div>
                <input value={color} onChange={e => {
                  const v = e.target.value;
                  if (/^#?[0-9a-fA-F]{0,6}$/.test(v)) setColor(v.startsWith('#') ? v : '#' + v);
                }} style={{
                  width: '100%', border: 'none', background: 'transparent', outline: 'none',
                  fontSize: 18, fontWeight: 600, color: theme.ink, marginTop: 2,
                  fontFamily: '"SF Mono", ui-monospace, monospace', letterSpacing: 1,
                }} />
              </div>
            </div>
            {/* recent tints row */}
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
              {['#ff6b35','#f7a440','#e8c547','#6aa84f','#45b1e8','#6864d8','#c85a7c','#8b5a3c','#4a4a4a','#000000'].map(c => (
                <button key={c} onClick={() => setColor(c)} style={{
                  width: 26, height: 26, borderRadius: 8, background: c, cursor: 'pointer',
                  border: color.toLowerCase() === c ? `2px solid ${theme.ink}` : `1px solid ${theme.line}`,
                }} />
              ))}
            </div>
          </div>
        )}
      </div>

      {isEdit && (
        <div style={{ padding: '24px 16px 0' }}>
          <button onClick={() => { if (confirm('このアクティビティを削除しますか？')) { onDelete(editingAct.id); goto('tracker'); } }} style={{
            width: '100%', padding: '14px', borderRadius: 14, border: 'none',
            background: theme.card, color: '#c0392b', fontSize: 15, fontWeight: 600,
            cursor: 'pointer', fontFamily: 'inherit',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          }}>
            <Icon name="trash" size={16} color="#c0392b" />
            アクティビティを削除
          </button>
        </div>
      )}
    </div>
  );
}
// ── Report ────────────────────────────────────────────────
const MONTH_DATA = Array.from({ length: 30 }, (_, i) => {
  const w = WEEK_DATA[i % 7];
  const variance = 0.7 + ((i * 7) % 10) / 20;
  const obj = { d: String(i + 1) };
  ACTIVITIES.forEach(a => { obj[a.id] = Math.round((w[a.id] || 0) * variance); });
  return obj;
});
const YEAR_DATA = ['1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月'].map((m, i) => {
  const base = 0.85 + (i % 4) * 0.08;
  const obj = { d: m };
  ACTIVITIES.forEach(a => {
    const weekly = WEEK_DATA.reduce((s, d) => s + (d[a.id] || 0), 0);
    obj[a.id] = Math.round(weekly * 4.3 * base);
  });
  return obj;
});

function ReportScreen({ theme, goto }) {
  const [period, setPeriod] = React.useState('week');
  const [offset, setOffset] = React.useState(0);

  const cfg = {
    day:   { rangeLabel: '2026年4月20日 月曜',        bars: 12, data: TIMELINE, chart: 'timeline', subtitle: '今日' },
    week:  { rangeLabel: '4月14日 – 4月20日',          bars: 7,  data: WEEK_DATA,  chart: 'stack',   subtitle: '今週' },
    month: { rangeLabel: '2026年4月',                   bars: 30, data: MONTH_DATA, chart: 'stack',   subtitle: '今月' },
    year:  { rangeLabel: '2026年',                      bars: 12, data: YEAR_DATA,  chart: 'stack',   subtitle: '今年' },
  };
  const c = cfg[period];

  // Totals for the chosen period
  const total = {};
  if (period === 'day') {
    // derive totals from TIMELINE: minutes per act
    const toMin = s => { const [h,m] = s.split(':').map(Number); return h*60+m; };
    TIMELINE.forEach(t => {
      total[t.act] = (total[t.act] || 0) + (toMin(t.end) - toMin(t.start));
    });
  } else {
    c.data.forEach(d => Object.entries(d).forEach(([k,v]) => { if (k !== 'd' && typeof v === 'number') total[k] = (total[k]||0) + v; }));
  }
  const sumAll = Object.values(total).reduce((s,v)=>s+v,0);

  return (
    <div style={{ padding: '0 0 120px', background: theme.bg, minHeight: '100%' }}>
      <div style={{ padding: '60px 20px 14px' }}>
        <div style={{ fontSize: 12, letterSpacing: 1.2, color: theme.inkMuted, fontWeight: 600, textTransform: 'uppercase' }}>
          Report
        </div>
        <div style={{ fontSize: 32, fontWeight: 700, color: theme.ink, letterSpacing: -0.8, marginTop: 2 }}>
          {c.subtitle}のレポート
        </div>
      </div>

      {/* period tabs */}
      <div style={{ padding: '0 20px 12px' }}>
        <div style={{
          display: 'flex', padding: 3, borderRadius: 12, background: theme.bgDeep, gap: 2,
        }}>
          {[['day','日'],['week','週'],['month','月'],['year','年']].map(([k,l]) => {
            const active = period === k;
            return (
              <button key={k} onClick={() => { setPeriod(k); setOffset(0); }} style={{
                flex: 1, border: 'none', padding: '7px 0', borderRadius: 9,
                fontSize: 14, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit',
                background: active ? theme.card : 'transparent',
                color: active ? theme.ink : theme.inkMuted,
                boxShadow: active ? '0 1px 2px rgba(0,0,0,0.08)' : 'none',
              }}>{l}</button>
            );
          })}
        </div>
      </div>

      {/* range navigator */}
      <div style={{ padding: '0 20px 16px', display: 'flex', alignItems: 'center', gap: 10 }}>
        <button onClick={() => setOffset(offset - 1)} style={{
          width: 34, height: 34, borderRadius: 10, background: theme.card, border: `1px solid ${theme.line}`,
          cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}><Icon name="chevronL" size={16} color={theme.ink} /></button>
        <div style={{ flex: 1, textAlign: 'center', fontSize: 15, fontWeight: 700, color: theme.ink, fontFeatureSettings: '"tnum"' }}>
          {c.rangeLabel}
        </div>
        <button onClick={() => setOffset(offset + 1)} disabled={offset >= 0} style={{
          width: 34, height: 34, borderRadius: 10, background: theme.card, border: `1px solid ${theme.line}`,
          cursor: offset >= 0 ? 'not-allowed' : 'pointer', opacity: offset >= 0 ? 0.4 : 1,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}><Icon name="chevron" size={16} color={theme.ink} /></button>
      </div>

      {/* Big total */}
      <div style={{ margin: '0 16px 16px', padding: '20px', borderRadius: 24,
        background: theme.card, boxShadow: '0 1px 2px rgba(0,0,0,0.03)' }}>
        <div style={{ fontSize: 11, letterSpacing: 1, color: theme.inkMuted, fontWeight: 700, textTransform: 'uppercase' }}>合計</div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 10, marginTop: 4 }}>
          <div style={{ fontSize: 40, fontWeight: 700, color: theme.ink, letterSpacing: -1, fontFeatureSettings: '"tnum"' }}>
            {fmtHMshort(sumAll)}
          </div>
          <div style={{ fontSize: 13, color: theme.inkMuted }}>
            {period === 'day' ? '' : period === 'week' ? `/ 日平均 ${fmtHMshort(sumAll/7)}` : period === 'month' ? `/ 日平均 ${fmtHMshort(sumAll/30)}` : `/ 月平均 ${fmtHMshort(sumAll/12)}`}
          </div>
        </div>

        {/* Chart */}
        <div style={{ marginTop: 18 }}>
          {c.chart === 'timeline' ? <TimelineRibbon theme={theme} /> : <StackBars data={c.data} period={period} theme={theme} />}
        </div>
      </div>

      {/* Breakdown */}
      <div style={{ padding: '4px 20px 8px', fontSize: 13, fontWeight: 700, color: theme.ink, letterSpacing: 0.5, textTransform: 'uppercase' }}>
        カテゴリ別
      </div>
      <div style={{ margin: '0 16px', padding: '4px 16px', borderRadius: 20, background: theme.card }}>
        {ACTIVITIES.filter(a => (total[a.id] || 0) > 0).sort((a,b) => (total[b.id]||0) - (total[a.id]||0)).map((a, i, arr) => {
          const v = total[a.id] || 0;
          const pct = sumAll ? Math.round(v/sumAll*100) : 0;
          return (
            <div key={a.id} style={{
              display: 'flex', alignItems: 'center', gap: 12, padding: '12px 0',
              borderBottom: i < arr.length - 1 ? `1px solid ${theme.line}` : 'none',
            }}>
              <div style={{ width: 10, height: 10, borderRadius: 2, background: a.color }} />
              <div style={{ flex: 1, fontSize: 15, fontWeight: 600, color: theme.ink }}>{a.label}</div>
              <div style={{ fontSize: 12, color: theme.inkMuted, fontFeatureSettings: '"tnum"', width: 36, textAlign: 'right' }}>{pct}%</div>
              <div style={{ fontSize: 15, fontWeight: 700, color: theme.ink, fontFeatureSettings: '"tnum"', width: 72, textAlign: 'right' }}>{fmtHMshort(v)}</div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

function StackBars({ data, period, theme }) {
  const maxDay = Math.max(...data.map(x => ACTIVITIES.reduce((s,a)=>s + (x[a.id]||0), 0)), 1);
  const maxH = 160;
  const gap = period === 'month' ? 2 : 6;
  const thin = data.length > 15;
  return (
    <div>
      <div style={{ display: 'flex', gap, alignItems: 'flex-end', height: maxH + 16 }}>
        {data.map((d, i) => {
          const dayTot = ACTIVITIES.reduce((s,a)=>s + (d[a.id]||0), 0);
          const scale = maxH / maxDay;
          const isCurrent = i === data.length - 1;
          return (
            <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, minWidth: 0 }}>
              <div style={{
                width: '100%', height: dayTot * scale, borderRadius: thin ? 2 : 6, overflow: 'hidden',
                display: 'flex', flexDirection: 'column-reverse',
                outline: isCurrent ? `2px solid ${theme.ink}22` : 'none', outlineOffset: 2,
              }}>
                {ACTIVITIES.map(a => {
                  const v = d[a.id] || 0;
                  if (v <= 0) return null;
                  return <div key={a.id} style={{ height: v * scale, background: a.color }} />;
                })}
              </div>
            </div>
          );
        })}
      </div>
      {/* x labels — sparse for month */}
      <div style={{ display: 'flex', gap, marginTop: 6 }}>
        {data.map((d, i) => {
          const show = period === 'month' ? (i === 0 || (i+1) % 5 === 0 || i === data.length - 1) : true;
          return (
            <div key={i} style={{
              flex: 1, textAlign: 'center', fontSize: 10,
              color: i === data.length - 1 ? theme.accent : theme.inkMuted,
              fontWeight: i === data.length - 1 ? 700 : 500,
            }}>{show ? d.d : ''}</div>
          );
        })}
      </div>
    </div>
  );
}

function TimelineRibbon({ theme }) {
  const toMin = s => { const [h,m] = s.split(':').map(Number); return h*60+m; };
  const start = 6*60, end = 18*60;
  return (
    <div>
      <div style={{ position: 'relative', height: 44, borderRadius: 8, overflow: 'hidden', background: theme.bgDeep }}>
        {TIMELINE.map((seg, i) => {
          const s = toMin(seg.start) - start;
          const e = toMin(seg.end) - start;
          const pctS = (s / (end - start)) * 100;
          const pctW = ((e - s) / (end - start)) * 100;
          const act = getActivity(seg.act);
          return (
            <div key={i} title={`${act.label} ${seg.start}-${seg.end}`} style={{
              position: 'absolute', top: 0, left: `${pctS}%`, width: `${pctW}%`,
              height: '100%', background: act.color,
            }} />
          );
        })}
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6, fontSize: 10, color: theme.inkMuted, fontFeatureSettings: '"tnum"' }}>
        <span>06:00</span><span>09:00</span><span>12:00</span><span>15:00</span><span>18:00</span>
      </div>
    </div>
  );
}

// ── Timeline (day ribbon) ─────────────────────────────────
function TimelineView({ theme }) {
  const toMin = s => { const [h,m] = s.split(':').map(Number); return h*60+m; };
  const start = 6*60, end = 17*60;
  return (
    <div style={{
      margin: '16px', padding: '16px', borderRadius: 20, background: theme.card,
      boxShadow: '0 1px 2px rgba(0,0,0,0.03)',
    }}>
      <div style={{ fontSize: 13, fontWeight: 700, color: theme.ink, letterSpacing: 0.5, textTransform: 'uppercase', marginBottom: 12 }}>
        今日のタイムライン
      </div>
      <div style={{ position: 'relative', height: 36, borderRadius: 8, overflow: 'hidden', background: theme.bgDeep }}>
        {TIMELINE.map((seg, i) => {
          const s = toMin(seg.start) - start;
          const e = toMin(seg.end) - start;
          const pctS = (s / (end - start)) * 100;
          const pctW = ((e - s) / (end - start)) * 100;
          const act = getActivity(seg.act);
          return (
            <div key={i} style={{
              position: 'absolute', top: 0, left: `${pctS}%`, width: `${pctW}%`,
              height: '100%', background: act.color, opacity: 0.9,
            }} />
          );
        })}
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8, fontSize: 10, color: theme.inkMuted, fontFeatureSettings: '"tnum"' }}>
        <span>06:00</span><span>09:00</span><span>12:00</span><span>15:00</span><span>17:00</span>
      </div>
    </div>
  );
}

// ── Settings ──────────────────────────────────────────────
function SettingsScreen({ theme, themeName, setThemeName, goto }) {
  const Row = ({ label, value, last }) => (
    <div style={{
      display: 'flex', alignItems: 'center', padding: '14px 0',
      borderBottom: last ? 'none' : `1px solid ${theme.line}`,
    }}>
      <div style={{ flex: 1, fontSize: 15, color: theme.ink, fontWeight: 500 }}>{label}</div>
      <div style={{ fontSize: 14, color: theme.inkMuted }}>{value}</div>
      <div style={{ marginLeft: 8 }}><Icon name="chevron" size={14} color={theme.inkSubtle} /></div>
    </div>
  );
  return (
    <div style={{ padding: '0 0 120px', background: theme.bg, minHeight: '100%' }}>
      <div style={{ padding: '60px 20px 16px' }}>
        <div style={{ fontSize: 32, fontWeight: 700, color: theme.ink, letterSpacing: -0.8 }}>設定</div>
      </div>

      <div style={{ padding: '0 20px 6px', fontSize: 11, letterSpacing: 1, color: theme.inkMuted, fontWeight: 700, textTransform: 'uppercase' }}>外観</div>
      <div style={{ margin: '0 16px 20px', padding: '4px 16px', borderRadius: 16, background: theme.card }}>
        <div style={{ padding: '12px 0', borderBottom: `1px solid ${theme.line}` }}>
          <div style={{ fontSize: 15, color: theme.ink, fontWeight: 500, marginBottom: 10 }}>テーマ</div>
          <div style={{ display: 'flex', gap: 8 }}>
            {['amber','terracotta','olive'].map(k => {
              const t = THEMES[k];
              return (
                <button key={k} onClick={() => setThemeName(k)} style={{
                  flex: 1, padding: '12px 8px', borderRadius: 12,
                  background: t.bg, border: themeName === k ? `2px solid ${t.accent}` : `1px solid ${t.line}`,
                  cursor: 'pointer', fontFamily: 'inherit',
                  display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
                }}>
                  <div style={{ display: 'flex', gap: 4 }}>
                    <div style={{ width: 14, height: 14, borderRadius: 3, background: t.accent }} />
                    <div style={{ width: 14, height: 14, borderRadius: 3, background: t.card, border: `1px solid ${t.line}` }} />
                    <div style={{ width: 14, height: 14, borderRadius: 3, background: t.ink }} />
                  </div>
                  <div style={{ fontSize: 11, fontWeight: 600, color: t.ink }}>
                    {k === 'amber' ? 'Amber' : k === 'terracotta' ? 'Terra' : 'Olive'}
                  </div>
                </button>
              );
            })}
          </div>
        </div>
        <Row label="ダークモード" value="システム" last />
      </div>

      <div style={{ padding: '0 20px 6px', fontSize: 11, letterSpacing: 1, color: theme.inkMuted, fontWeight: 700, textTransform: 'uppercase' }}>計測</div>
      <div style={{ margin: '0 16px 20px', padding: '4px 16px', borderRadius: 16, background: theme.card }}>
        <Row label="自動一時停止" value="5分後" />
        <Row label="アイドル検知" value="オン" />
        <Row label="ロック画面ウィジェット" value="許可" last />
      </div>

      <div style={{ padding: '0 20px 6px', fontSize: 11, letterSpacing: 1, color: theme.inkMuted, fontWeight: 700, textTransform: 'uppercase' }}>データ</div>
      <div style={{ margin: '0 16px 20px', padding: '4px 16px', borderRadius: 16, background: theme.card }}>
        <Row label="エクスポート" value="CSV · JSON" />
        <Row label="バックアップ" value="iCloud" last />
      </div>
    </div>
  );
}

Object.assign(window, { ActivityDetail, CreateScreen, ReportScreen, SettingsScreen, TimelineView, StatCard });
