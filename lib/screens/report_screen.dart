import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/activity.dart';
import '../models/sample_data.dart';

class ReportScreen extends StatefulWidget {
  final AppColors colors;
  const ReportScreen({super.key, required this.colors});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _period = 'week';

  Map<String, int> get _totals {
    final data = _period == 'week' ? kWeekData : kWeekData;
    final result = <String, int>{};
    for (final day in data) {
      day.minutes.forEach((k, v) { result[k] = (result[k] ?? 0) + v; });
    }
    return result;
  }

  String get _subtitle {
    switch (_period) {
      case 'day': return '今日';
      case 'week': return '今週';
      case 'month': return '今月';
      default: return '今年';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final totals = _totals;
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
                      onTap: () => setState(() => _period = t.$1),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(fmtHMShort(sumAll), style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: c.ink, letterSpacing: -1)),
                      const SizedBox(width: 10),
                      Text('/ 日平均 ${fmtHMShort(sumAll ~/ 7)}', style: TextStyle(fontSize: 13, color: c.inkMuted)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _StackBars(data: kWeekData, colors: c),
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
              child: Column(
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
  }
}

class _StackBars extends StatelessWidget {
  final List<DayData> data;
  final AppColors colors;
  const _StackBars({required this.data, required this.colors});

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
              final isCurrent = i == data.length - 1;

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
            final isCurrent = i == data.length - 1;
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
