import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/activity.dart';
import '../models/sample_data.dart';
import '../services/local_db.dart';

class _ReportData {
  final Map<String, int> totals;
  final List<DayData> weekData;
  const _ReportData({required this.totals, required this.weekData});
}

class ReportScreen extends StatefulWidget {
  final AppColors colors;
  const ReportScreen({super.key, required this.colors});

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

  Future<_ReportData> _loadData() async {
    switch (_period) {
      case 'day':
        final totals = await LocalDb.getDayTotals(_dateStr(_referenceDate));
        return _ReportData(totals: totals, weekData: const []);
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

  bool get _isCurrentPeriod {
    final now = DateTime.now();
    switch (_period) {
      case 'day':   return _sameDay(_referenceDate, now);
      case 'week':
        final ws    = now.subtract(Duration(days: now.weekday - 1));
        final refWs = _referenceDate.subtract(Duration(days: _referenceDate.weekday - 1));
        return _sameDay(ws, refWs);
      case 'month': return _referenceDate.year == now.year && _referenceDate.month == now.month;
      default:      return _referenceDate.year >= now.year;
    }
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _goBack() {
    setState(() {
      _referenceDate = _shift(-1);
      _dataFuture = _loadData();
    });
  }

  void _goNext() {
    if (_isCurrentPeriod) return;
    setState(() {
      _referenceDate = _shift(1);
      _dataFuture = _loadData();
    });
  }

  DateTime _shift(int direction) {
    switch (_period) {
      case 'day':   return _referenceDate.add(Duration(days: direction));
      case 'week':  return _referenceDate.add(Duration(days: 7 * direction));
      case 'month': return DateTime(_referenceDate.year, _referenceDate.month + direction, 1);
      default:      return DateTime(_referenceDate.year + direction, 1, 1);
    }
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  String _avgLabel(int sumAll) {
    switch (_period) {
      case 'week':  return '/ 日平均 ${fmtHMShort(sumAll ~/ 7)}';
      case 'month': return '/ 日平均 ${fmtHMShort(sumAll ~/ 30)}';
      case 'year':  return '/ 月平均 ${fmtHMShort(sumAll ~/ 12)}';
      default: return '';
    }
  }

  String get _subtitle {
    if (_isCurrentPeriod) {
      switch (_period) {
        case 'day':   return '今日';
        case 'week':  return '今週';
        case 'month': return '今月';
        default:      return '今年';
      }
    }
    switch (_period) {
      case 'day':   return '${_referenceDate.month}月${_referenceDate.day}日';
      case 'week':
        final ws = _referenceDate.subtract(Duration(days: _referenceDate.weekday - 1));
        return '${ws.month}/${ws.day.toString().padLeft(2,'0')}〜';
      case 'month': return '${_referenceDate.year}年${_referenceDate.month}月';
      default:      return '${_referenceDate.year}年';
    }
  }

  String get _dateLabel {
    final d = _referenceDate;
    String fmt(DateTime x) =>
        '${x.year}/${x.month.toString().padLeft(2, '0')}/${x.day.toString().padLeft(2, '0')}';
    String mm(DateTime x) =>
        '${x.month.toString().padLeft(2, '0')}/${x.day.toString().padLeft(2, '0')}';
    switch (_period) {
      case 'day': return fmt(d);
      case 'week':
        final start = d.subtract(Duration(days: d.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return '${fmt(start)} 〜 ${mm(end)}';
      case 'month': return '${d.year}/${d.month.toString().padLeft(2, '0')}';
      default:      return '${d.year}';
    }
  }

  // 週グラフで今日に対応する列インデックスを返す（この週でなければ -1）
  int _todayColumn() {
    final today = DateTime.now();
    final weekStart = _referenceDate.subtract(Duration(days: _referenceDate.weekday - 1));
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      if (_sameDay(day, today)) return i;
    }
    return -1;
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
        final sorted = kActivities.where((a) => (totals[a.id] ?? 0) > 0).toList()
          ..sort((a, b) => (totals[b.id] ?? 0).compareTo(totals[a.id] ?? 0));

        return SingleChildScrollView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            bottom: 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('REPORT', style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600, color: c.inkMuted)),
                    const SizedBox(height: 2),
                    Text('$_subtitle のレポート', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: c.ink, letterSpacing: -0.8)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: _goBack,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            child: Icon(Icons.chevron_left, size: 22, color: c.ink),
                          ),
                        ),
                        Text(_dateLabel, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink)),
                        GestureDetector(
                          onTap: _isCurrentPeriod ? null : _goNext,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            child: Icon(
                              Icons.chevron_right,
                              size: 22,
                              color: _isCurrentPeriod ? c.inkMuted.withAlpha(80) : c.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Period tabs
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
                            Text(fmtHMShort(sumAll), style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: c.ink, letterSpacing: -1)),
                            const SizedBox(width: 10),
                            Text(_avgLabel(sumAll), style: TextStyle(fontSize: 13, color: c.inkMuted)),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (_period == 'week')
                          _StackBars(data: weekData, colors: c, todayIndex: _todayColumn())
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
                                  SizedBox(width: 72, child: Text(fmtHMShort(v), textAlign: TextAlign.right, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.ink))),
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
  final int todayIndex; // -1 = ハイライトなし

  const _StackBars({required this.data, required this.colors, this.todayIndex = -1});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final maxDay = data.map((d) => kActivities.fold(0, (s, a) => s + (d.minutes[a.id] ?? 0))).fold(0, math.max);

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.asMap().entries.map((entry) {
              final i = entry.key;
              final d = entry.value;
              final dayTotal = kActivities.fold(0, (s, a) => s + (d.minutes[a.id] ?? 0));
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
                          children: kActivities.map((act) {
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
