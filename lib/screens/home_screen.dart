import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/activity.dart';
import '../models/sample_data.dart';
import '../services/local_db.dart';
import '../widgets/donut_chart.dart';
import '../widgets/act_icon.dart';

class HomeScreen extends StatefulWidget {
  final AppColors colors;
  final String? activeId;
  final Activity? activeActivity;
  final int elapsed;
  final bool paused;
  final VoidCallback onPause;
  final VoidCallback onGoTracker;
  final VoidCallback onGoReport;
  final VoidCallback onGoSettings;
  final void Function(String) onSelectActivity;

  const HomeScreen({
    super.key,
    required this.colors,
    this.activeId,
    this.activeActivity,
    this.elapsed = 0,
    this.paused = false,
    required this.onPause,
    required this.onGoTracker,
    required this.onGoReport,
    required this.onGoSettings,
    required this.onSelectActivity,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

String _todayLabel() {
  final now = DateTime.now();
  const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
  final wd = weekdays[now.weekday - 1];
  return '${now.year}年${now.month}月${now.day}日 $wd曜';
}

class _HomeScreenState extends State<HomeScreen> {
  String _period = 'day';
  Map<String, int> _monthData = {};
  Map<String, int> _weekData = {};
  bool _asyncLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAsync('week');
  }

  Future<void> _loadAsync(String period) async {
    if (_asyncLoading) return;
    _asyncLoading = true;
    try {
      if (period == 'week') {
        final weekList = await LocalDb.getWeekData();
        final agg = <String, int>{};
        for (final day in weekList) {
          day.minutes.forEach((k, v) { agg[k] = (agg[k] ?? 0) + v; });
        }
        if (mounted) setState(() => _weekData = agg);
      } else if (period == 'month') {
        final data = await LocalDb.getMonthTotals();
        if (mounted) setState(() => _monthData = data);
      }
    } finally {
      _asyncLoading = false;
    }
  }

  void _switchPeriod(String period) {
    setState(() => _period = period);
    if (period == 'week') _loadAsync('week');
    if (period == 'month') _loadAsync('month');
  }

  Map<String, int> get _data {
    if (_period == 'day') return kTodayMin;
    if (_period == 'month') return _monthData;
    return _weekData;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final data = _data;
    final total = data.values.fold(0, (s, v) => s + v);
    final sorted = data.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final segments = kAllActivities
        .where((a) => (data[a.id] ?? 0) > 0)
        .map((a) => DonutSegment(id: a.id, color: a.color, value: data[a.id]!))
        .toList();

    final centerLabel = _period == 'day' ? '記録' : _period == 'week' ? '今週' : '今月';

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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _todayLabel(),
                        style: TextStyle(
                          fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600,
                          color: c.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '今日の記録',
                        style: TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w700,
                          color: c.ink, letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: widget.onGoSettings,
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.line),
                    ),
                    child: Center(child: ActIcon(icon: 'gear', size: 18, color: c.ink)),
                  ),
                ),
              ],
            ),
          ),

          // Live bar
          if (widget.activeActivity != null) _LiveBar(
            activeActivity: widget.activeActivity!,
            elapsed: widget.elapsed,
            paused: widget.paused,
            colors: c,
            onTap: widget.onGoTracker,
            onPause: widget.onPause,
          ),

          // Period tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: _PeriodTabs(value: _period, onChange: _switchPeriod, colors: c),
          ),

          // Donut card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 30, offset: const Offset(0, 10)),
                ],
              ),
              child: Row(
                children: [
                  DonutChart(
                    segments: segments,
                    colors: c,
                    size: 160,
                    thickness: 22,
                    centerLabel: centerLabel,
                    centerValue: fmtHMShort(total ~/ 60),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: segments.take(4).map((seg) {
                        final act = getActivity(seg.id);
                        final pct = total > 0 ? ((seg.value / total) * 100).round() : 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: act.color, borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 8),
                              Expanded(child: Text(act.label, style: TextStyle(fontSize: 13, color: c.ink, fontWeight: FontWeight.w500))),
                              Text('$pct%', style: TextStyle(fontSize: 12, color: c.inkMuted, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Category breakdown header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                Text('カテゴリ別', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.ink, letterSpacing: 0.6)),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onGoReport,
                  child: Text('詳細レポート →', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.accent)),
                ),
              ],
            ),
          ),

          // Category list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: sorted.asMap().entries.map((e) {
                  final act = getActivity(e.value.key);
                  final pct = total > 0 ? e.value.value / total : 0.0;
                  final isLast = e.key == sorted.length - 1;
                  return _CategoryRow(act: act, minutes: e.value.value, pct: pct, colors: c, isLast: isLast, onTap: () => widget.onSelectActivity(e.value.key));
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick shortcut
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: widget.onGoTracker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: c.ink, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ActIcon(icon: 'timer', size: 18, color: c.bg),
                    const SizedBox(width: 8),
                    Text('アクティビティを計測', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.bg)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  final String value;
  final void Function(String) onChange;
  final AppColors colors;

  const _PeriodTabs({required this.value, required this.onChange, required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final tabs = [('day', '日'), ('week', '週'), ('month', '月')];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: c.bgDeep, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: tabs.map((t) {
          final active = value == t.$1;
          return GestureDetector(
            onTap: () => onChange(t.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: active ? c.card : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                boxShadow: active ? [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 2)] : null,
              ),
              child: Text(
                t.$2,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: active ? c.ink : c.inkMuted),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final Activity act;
  final int minutes;
  final double pct;
  final AppColors colors;
  final bool isLast;
  final VoidCallback onTap;

  const _CategoryRow({required this.act, required this.minutes, required this.pct, required this.colors, this.isLast = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: isLast ? null : BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: act.tint, borderRadius: BorderRadius.circular(10)),
              child: Center(child: ActIcon(icon: act.icon, size: 20, color: act.color, imagePath: act.imagePath)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(act.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink))),
                      Text(fmtHMShort(minutes ~/ 60), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: c.bgDeep,
                      valueColor: AlwaysStoppedAnimation(act.color),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveBar extends StatelessWidget {
  final Activity activeActivity;
  final int elapsed;
  final bool paused;
  final AppColors colors;
  final VoidCallback onTap;
  final VoidCallback onPause;

  const _LiveBar({
    required this.activeActivity, required this.elapsed, required this.paused,
    required this.colors, required this.onTap, required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    final act = activeActivity;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: act.color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: act.color.withAlpha(64), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: Colors.white.withAlpha(56), borderRadius: BorderRadius.circular(10)),
              child: Center(child: ActIcon(icon: act.icon, size: 18, color: Colors.white, imagePath: act.imagePath)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(paused ? '一時停止中' : '計測中', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 0.8)),
                  Text(act.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
            ),
            Text(fmtClock(elapsed), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onPause,
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: Colors.white.withAlpha(64), shape: BoxShape.circle),
                child: Center(child: ActIcon(icon: paused ? 'play' : 'pause', size: 14, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
