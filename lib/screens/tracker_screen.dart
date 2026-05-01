import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/activity.dart';
import '../models/sample_data.dart';
import '../widgets/act_icon.dart';

class TrackerScreen extends StatefulWidget {
  final AppColors colors;
  final String? activeId;
  final int elapsed;
  final bool paused;
  final DateTime? startTime;
  final void Function(String) onTap;
  final VoidCallback onPause;
  final VoidCallback onStop;

  const TrackerScreen({
    super.key,
    required this.colors,
    this.activeId,
    this.elapsed = 0,
    this.paused = false,
    this.startTime,
    required this.onTap,
    required this.onPause,
    required this.onStop,
  });

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  int _cols = 2;
  bool _editing = false;
  final List<String> _order = ['workA', 'workB', 'game', 'move', 'sleep', 'other'];

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TRACKER', style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600, color: c.inkMuted)),
                      const SizedBox(height: 2),
                      Text('計測', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: c.ink, letterSpacing: -0.8)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(color: c.bgDeep, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [2, 3].map((n) {
                          final active = _cols == n;
                          return GestureDetector(
                            onTap: () => setState(() => _cols = n),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 36, height: 32,
                              decoration: BoxDecoration(
                                color: active ? c.card : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Center(
                                child: Icon(
                                  n == 2 ? Icons.grid_view : Icons.apps,
                                  size: 18,
                                  color: active ? c.ink : c.inkMuted,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _editing = !_editing),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: _editing ? c.ink : c.card,
                          borderRadius: BorderRadius.circular(10),
                          border: _editing ? null : Border.all(color: c.line),
                        ),
                        child: Center(
                          child: Text(
                            _editing ? '完了' : '編集',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _editing ? c.bg : c.ink),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Live timer bar
          _LiveTimerBar(
            activeId: widget.activeId,
            elapsed: widget.elapsed,
            paused: widget.paused,
            startTime: widget.startTime,
            onPause: widget.onPause,
            onStop: widget.onStop,
            colors: c,
          ),

          if (widget.activeId == null && !_editing)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('タイルをタップで計測開始・別タイルをタップで即切替', style: TextStyle(fontSize: 12, color: c.inkMuted)),
            ),

          if (_editing)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('タップで編集・−で削除', style: TextStyle(fontSize: 12, color: c.inkMuted)),
            ),

          // Activity grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _cols,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: _cols == 2 ? 1.2 : 1.05,
              ),
              itemCount: _order.length + 1,
              itemBuilder: (context, index) {
                if (index == _order.length) {
                  return _AddTile(colors: c, onTap: () {});
                }
                final id = _order[index];
                final act = getActivity(id);
                final isActive = widget.activeId == id;
                return _ActivityTile(
                  act: act,
                  isActive: isActive && !_editing,
                  elapsed: isActive ? widget.elapsed : 0,
                  todayMin: kTodayMin[id] ?? 0,
                  editing: _editing,
                  colors: c,
                  onTap: () { if (!_editing) widget.onTap(id); },
                  onRemove: () => setState(() => _order.remove(id)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveTimerBar extends StatelessWidget {
  final String? activeId;
  final int elapsed;
  final bool paused;
  final DateTime? startTime;
  final VoidCallback onPause;
  final VoidCallback onStop;
  final AppColors colors;

  const _LiveTimerBar({
    required this.activeId, required this.elapsed, required this.paused,
    this.startTime, required this.onPause, required this.onStop, required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    if (activeId == null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.line, width: 1.5, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: c.bgDeep, borderRadius: BorderRadius.circular(10)),
              child: Center(child: ActIcon(icon: 'timer', size: 18, color: c.inkMuted)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('計測していません', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink)),
                  Text('下のタイルをタップして開始', style: TextStyle(fontSize: 12, color: c.inkMuted)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final act = getActivity(activeId!);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: act.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: act.color.withAlpha(85), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(paused ? '一時停止中' : '計測中', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.white)),
              const Spacer(),
              if (startTime != null)
                Text('開始 ${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.white.withAlpha(56), borderRadius: BorderRadius.circular(12)),
                child: Center(child: ActIcon(icon: act.icon, size: 22, color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(act.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    Text(fmtClock(elapsed), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -1)),
                  ],
                ),
              ),
              Row(
                children: [
                  _CircleBtn(icon: paused ? 'play' : 'pause', onTap: onPause),
                  const SizedBox(width: 6),
                  _CircleBtn(icon: 'stop', onTap: onStop),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(color: Colors.white.withAlpha(64), shape: BoxShape.circle),
        child: Center(child: ActIcon(icon: icon, size: 16, color: Colors.white)),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Activity act;
  final bool isActive;
  final int elapsed;
  final int todayMin;
  final bool editing;
  final AppColors colors;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ActivityTile({
    required this.act, required this.isActive, required this.elapsed,
    required this.todayMin, required this.editing, required this.colors,
    required this.onTap, required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final bg = isActive ? act.color : c.card;
    final textColor = isActive ? Colors.white : c.ink;
    final subColor = isActive ? Colors.white70 : c.inkMuted;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(22),
              boxShadow: isActive
                  ? [BoxShadow(color: act.color.withAlpha(85), blurRadius: 24, offset: const Offset(0, 8))]
                  : [const BoxShadow(color: Color(0x0A2A1E14), blurRadius: 20, offset: Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white.withAlpha(56) : act.tint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: ActIcon(icon: act.icon, size: 22, color: isActive ? Colors.white : act.color)),
                    ),
                    const Spacer(),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white.withAlpha(56), borderRadius: BorderRadius.circular(6)),
                        child: const Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.8)),
                      ),
                    if (editing)
                      Icon(Icons.drag_indicator, size: 16, color: c.inkSubtle),
                  ],
                ),
                const Spacer(),
                Text(act.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor, letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text(
                  editing ? 'タップで編集' : (isActive ? fmtClock(elapsed) : (todayMin > 0 ? '今日 ${fmtHMShort(todayMin)}' : '—')),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subColor),
                ),
              ],
            ),
          ),
        ),
        if (editing)
          Positioned(
            top: -6, left: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 24, height: 24,
                decoration: const BoxDecoration(color: Color(0xFFE11D48), shape: BoxShape.circle),
                child: const Center(child: Text('−', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, height: 1))),
              ),
            ),
          ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  final AppColors colors;
  final VoidCallback onTap;
  const _AddTile({required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: c.line, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ActIcon(icon: 'plus', size: 22, color: c.inkMuted),
            const SizedBox(height: 6),
            Text('追加', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.inkMuted)),
          ],
        ),
      ),
    );
  }
}
