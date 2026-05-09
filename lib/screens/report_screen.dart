import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/activity.dart';
import '../models/sample_data.dart';
import '../services/local_db.dart';

class _ReportData {
  final Map<String, int> totals;
  final List<DayData> weekData;
  final List<SessionRecord> sessions;
  const _ReportData({required this.totals, required this.weekData, this.sessions = const []});
}

class ReportScreen extends StatefulWidget {
  final AppColors colors;
  final int refreshTrigger;
  const ReportScreen({super.key, required this.colors, this.refreshTrigger = 0});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _period = 'week';
  DateTime _referenceDate = DateTime.now();
  late Future<_ReportData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  @override
  void didUpdateWidget(ReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      setState(() => _dataFuture = _loadData());
    }
  }

  Future<_ReportData> _loadData() async {
    switch (_period) {
      case 'day':
        final dateStr = _dateStr(_referenceDate);
        final results = await Future.wait([
          LocalDb.getDayTotals(dateStr),
          LocalDb.getByDate(dateStr),
        ]);
        return _ReportData(
          totals: results[0] as Map<String, int>,
          weekData: const [],
          sessions: results[1] as List<SessionRecord>,
        );
      case 'week':
        final weekData = await LocalDb.getWeekData(_referenceDate);
        final totals = <String, int>{};
        for (final d in weekData) {
          d.minutes.forEach((k, v) { totals[k] = (totals[k] ?? 0) + v; });
        }
        return _ReportData(totals: totals, weekData: weekData);
      case 'month':
        final totals = await LocalDb.getMonthTotals(_referenceDate);
        return _ReportData(totals: totals, weekData: const []);
      default: // 'year'
        final totals = await LocalDb.getYearTotals(_referenceDate.year);
        return _ReportData(totals: totals, weekData: const []);
    }
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _isAtPresent {
    final now = DateTime.now();
    switch (_period) {
      case 'day':
        return _isSameDay(_referenceDate, now);
      case 'week':
        final nowWeekStart = now.subtract(Duration(days: now.weekday - 1));
        final refWeekStart = _referenceDate.subtract(Duration(days: _referenceDate.weekday - 1));
        return _isSameDay(refWeekStart, nowWeekStart);
      case 'month':
        return _referenceDate.year == now.year && _referenceDate.month == now.month;
      default:
        return _referenceDate.year >= now.year;
    }
  }

  static String _p(int n) => n.toString().padLeft(2, '0');

  String get _navLabel {
    switch (_period) {
      case 'day':
        return '${_referenceDate.year}年${_p(_referenceDate.month)}月${_p(_referenceDate.day)}日';
      case 'week':
        final ws = _referenceDate.subtract(Duration(days: _referenceDate.weekday - 1));
        final we = ws.add(const Duration(days: 6));
        return '${_p(ws.month)}/${_p(ws.day)} - ${_p(we.month)}/${_p(we.day)}';
      case 'month':
        return '${_referenceDate.year}年${_p(_referenceDate.month)}月';
      default:
        return '${_referenceDate.year}年';
    }
  }

  String _avgLabel(int sumAll) {
    switch (_period) {
      case 'week':  return '/ 日平均 ${fmtHMShort(sumAll ~/ (7 * 60))}';
      case 'month': return '/ 日平均 ${fmtHMShort(sumAll ~/ (30 * 60))}';
      case 'year':  return '/ 月平均 ${fmtHMShort(sumAll ~/ (12 * 60))}';
      default: return '';
    }
  }

  String get _presentLabel {
    switch (_period) {
      case 'day':   return '今日';
      case 'week':  return '今週';
      case 'month': return '今月';
      default:      return '今年';
    }
  }

  void _resetToPresent() {
    setState(() {
      _referenceDate = DateTime.now();
      _dataFuture = _loadData();
    });
  }

  void _navigate(int dir) {
    final ref = _referenceDate;
    final DateTime next;
    switch (_period) {
      case 'day':
        next = ref.add(Duration(days: dir));
      case 'week':
        next = ref.add(Duration(days: dir * 7));
      case 'month':
        next = DateTime(ref.year, ref.month + dir, 1);
      default:
        next = DateTime(ref.year + dir, ref.month, ref.day);
    }
    setState(() {
      _referenceDate = next;
      _dataFuture = _loadData();
    });
  }

  int _todayColumnIndex() {
    if (_period != 'week' || !_isAtPresent) return -1;
    return DateTime.now().weekday - 1;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return FutureBuilder<_ReportData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        final totals = snapshot.data?.totals ?? {};
        final weekData = snapshot.data?.weekData ?? [];
        final isLoading = !snapshot.hasData;

        final sumAll = totals.values.fold(0, (s, v) => s + v);
        final sorted = kAllActivities.where((a) => (totals[a.id] ?? 0) > 0).toList()
          ..sort((a, b) => (totals[b.id] ?? 0).compareTo(totals[a.id] ?? 0));

        return SingleChildScrollView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            bottom: 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('REPORT', style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600, color: c.inkMuted)),
                    const SizedBox(height: 2),
                    Text('レポート', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: c.ink, letterSpacing: -0.8)),
                  ],
                ),
              ),

              // Period tabs
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: c.bgDeep, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [('day', '日'), ('week', '週'), ('month', '月'), ('year', '年')].map((t) {
                      final active = _period == t.$1;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _period = t.$1;
                            _referenceDate = DateTime.now();
                            _dataFuture = _loadData();
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color: active ? c.card : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: active ? [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 2)] : null,
                            ),
                            child: Center(
                              child: Text(t.$2, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: active ? c.ink : c.inkMuted)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Date navigation
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: c.ink),
                      onPressed: () => _navigate(-1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    Text(
                      _navLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right, color: _isAtPresent ? c.inkMuted.withAlpha(80) : c.ink),
                      onPressed: _isAtPresent ? null : () => _navigate(1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _isAtPresent ? null : _resetToPresent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _isAtPresent ? c.bgDeep : c.accent.withAlpha(24),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _presentLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isAtPresent ? c.inkMuted : c.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Total card + bar chart
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 20)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('合計', style: TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w700, color: c.inkMuted)),
                      const SizedBox(height: 4),
                      if (isLoading)
                        const Center(child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ))
                      else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(fmtHMShort(sumAll ~/ 60), style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: c.ink, letterSpacing: -1)),
                            const SizedBox(width: 10),
                            Text(_avgLabel(sumAll), style: TextStyle(fontSize: 13, color: c.inkMuted)),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (_period == 'week')
                          _StackBars(data: weekData, colors: c, todayIndex: _todayColumnIndex())
                        else if (_period == 'day')
                          _TimelineBar(sessions: snapshot.data?.sessions ?? [], colors: c)
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('棒グラフは週表示のみ対応しています', style: TextStyle(fontSize: 12, color: c.inkMuted)),
                          ),
                      ],
                    ],
                  ),
                ),
              ),

              // Breakdown
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text('カテゴリ別', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.ink, letterSpacing: 0.5)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(20)),
                  child: isLoading
                      ? const Center(child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ))
                      : Column(
                          children: sorted.asMap().entries.map((entry) {
                            final i = entry.key;
                            final act = entry.value;
                            final v = totals[act.id] ?? 0;
                            final pct = sumAll > 0 ? (v / sumAll * 100).round() : 0;
                            final isLast = i == sorted.length - 1;
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: isLast ? null : Border(bottom: BorderSide(color: c.line)),
                              ),
                              child: Row(
                                children: [
                                  Container(width: 10, height: 10, decoration: BoxDecoration(color: act.color, borderRadius: BorderRadius.circular(2))),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(act.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink))),
                                  SizedBox(width: 36, child: Text('$pct%', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: c.inkMuted))),
                                  SizedBox(width: 72, child: Text(fmtHMShort(v ~/ 60), textAlign: TextAlign.right, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.ink))),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StackBars extends StatelessWidget {
  final List<DayData> data;
  final AppColors colors;
  final int todayIndex;

  const _StackBars({required this.data, required this.colors, this.todayIndex = -1});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final maxDay = data.map((d) => kAllActivities.fold(0, (s, a) => s + (d.minutes[a.id] ?? 0))).fold(0, math.max);

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.asMap().entries.map((entry) {
              final i = entry.key;
              final d = entry.value;
              final dayTotal = kAllActivities.fold(0, (s, a) => s + (d.minutes[a.id] ?? 0));
              final barH = maxDay > 0 ? (dayTotal / maxDay) * 140.0 : 0.0;
              final isCurrent = i == todayIndex;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: barH,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: isCurrent ? Border.all(color: c.ink.withAlpha(22), width: 2) : null,
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Column(
                          verticalDirection: VerticalDirection.up,
                          children: kAllActivities.map((act) {
                            final v = d.minutes[act.id] ?? 0;
                            if (v <= 0) return const SizedBox.shrink();
                            return Expanded(
                              flex: v,
                              child: Container(color: act.color),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: data.asMap().entries.map((entry) {
            final i = entry.key;
            final d = entry.value;
            final isCurrent = i == todayIndex;
            return Expanded(
              child: Text(
                d.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: isCurrent ? c.accent : c.inkMuted,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TimelineBar extends StatelessWidget {
  final List<SessionRecord> sessions;
  final AppColors colors;

  const _TimelineBar({required this.sessions, required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    const barHeight = 36.0;
    const labelHeight = 16.0;
    const totalSeconds = 86400.0;
    const hourLabels = [0, 6, 12, 18, 24];

    if (sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('記録なし', style: TextStyle(fontSize: 12, color: c.inkMuted)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: barHeight + labelHeight + 4,
          child: Stack(
            children: [
              // Background track
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: barHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: c.bgDeep,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              // Session blocks
              ...sessions.map((s) {
                final startDt = DateTime.fromMillisecondsSinceEpoch(s.startedAt);
                final startSec = startDt.hour * 3600.0 + startDt.minute * 60.0 + startDt.second;
                final left = (startSec / totalSeconds) * width;
                final rawWidth = (s.durationSeconds / totalSeconds) * width;
                final blockWidth = rawWidth.clamp(4.0, width - left);
                final actColor = _colorForId(s.activityId);
                return Positioned(
                  top: 0,
                  left: left,
                  width: blockWidth,
                  height: barHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: actColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
              // Hour labels
              ...hourLabels.map((h) {
                final x = (h / 24.0) * width;
                return Positioned(
                  top: barHeight + 4,
                  left: h == 24 ? x - 16 : x,
                  child: Text(
                    '$h',
                    style: TextStyle(fontSize: 9, color: c.inkMuted),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Color _colorForId(String activityId) {
    try {
      return kAllActivities.firstWhere((a) => a.id == activityId).color;
    } catch (_) {
      return const Color(0xFF9E9E9E);
    }
  }
}
