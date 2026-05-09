import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/activity.dart';

class SessionRecord {
  final int? id;
  final String activityId;
  final String activityLabel;
  final int durationSeconds; // 秒単位で保存
  final String date; // YYYY-MM-DD
  final int startedAt; // unix timestamp (ms)
  final bool synced;

  const SessionRecord({
    this.id,
    required this.activityId,
    required this.activityLabel,
    required this.durationSeconds,
    required this.date,
    required this.startedAt,
    this.synced = false,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'activityId': activityId,
    'activityLabel': activityLabel,
    'durationSeconds': durationSeconds,
    'date': date,
    'startedAt': startedAt,
    'synced': synced ? 1 : 0,
  };

  factory SessionRecord.fromMap(Map<String, dynamic> m) => SessionRecord(
    id: m['id'] as int?,
    activityId: m['activityId'] as String,
    activityLabel: m['activityLabel'] as String,
    durationSeconds: m['durationSeconds'] as int,
    date: m['date'] as String,
    startedAt: m['startedAt'] as int,
    synced: (m['synced'] as int) == 1,
  );

  SessionRecord copyWith({bool? synced}) => SessionRecord(
    id: id,
    activityId: activityId,
    activityLabel: activityLabel,
    durationSeconds: durationSeconds,
    date: date,
    startedAt: startedAt,
    synced: synced ?? this.synced,
  );
}

class LocalDb {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'sessions.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE sessions (
          id              INTEGER PRIMARY KEY AUTOINCREMENT,
          activityId      TEXT NOT NULL,
          activityLabel   TEXT NOT NULL,
          durationSeconds INTEGER NOT NULL,
          date            TEXT NOT NULL,
          startedAt       INTEGER NOT NULL,
          synced          INTEGER NOT NULL DEFAULT 0
        )
      '''),
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS sessions');
        await db.execute('''
          CREATE TABLE sessions (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            activityId      TEXT NOT NULL,
            activityLabel   TEXT NOT NULL,
            durationSeconds INTEGER NOT NULL,
            date            TEXT NOT NULL,
            startedAt       INTEGER NOT NULL,
            synced          INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  static Future<int> insert(SessionRecord r) async {
    final d = await db;
    return d.insert('sessions', r.toMap());
  }

  static Future<List<SessionRecord>> getAll() async {
    final d = await db;
    final rows = await d.query('sessions');
    return rows.map(SessionRecord.fromMap).toList();
  }

  static Future<List<SessionRecord>> getByDate(String date) async {
    final d = await db;
    final rows = await d.query('sessions', where: 'date = ?', whereArgs: [date]);
    return rows.map(SessionRecord.fromMap).toList();
  }

  static Future<List<SessionRecord>> getUnsynced() async {
    final d = await db;
    final rows = await d.query('sessions', where: 'synced = 0');
    return rows.map(SessionRecord.fromMap).toList();
  }

  static Future<void> clearAll() async {
    final d = await db;
    await d.delete('sessions');
  }

  static Future<void> markSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    final d = await db;
    await d.update(
      'sessions',
      {'synced': 1},
      where: 'id IN (${ids.map((_) => '?').join(',')})',
      whereArgs: ids,
    );
  }

  // 指定した日付範囲の activityId ごとの合計秒数
  static Future<Map<String, int>> _getTotalsInRange(String from, String to) async {
    final d = await db;
    final rows = await d.query(
      'sessions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [from, to],
    );
    final totals = <String, int>{};
    for (final row in rows) {
      final r = SessionRecord.fromMap(row);
      totals[r.activityId] = (totals[r.activityId] ?? 0) + r.durationSeconds;
    }
    return totals;
  }

  // 指定日の activityId ごとの合計秒数
  static Future<Map<String, int>> getDayTotals(String date) async {
    final records = await getByDate(date);
    final totals = <String, int>{};
    for (final r in records) {
      totals[r.activityId] = (totals[r.activityId] ?? 0) + r.durationSeconds;
    }
    return totals;
  }

  // 今日の activityId ごとの合計秒数
  static Future<Map<String, int>> getTodayTotals() async {
    return getDayTotals(_dateStr(DateTime.now()));
  }

  // 今月の activityId ごとの合計秒数
  static Future<Map<String, int>> getMonthTotals([DateTime? baseDate]) async {
    final d = baseDate ?? DateTime.now();
    final from = '${d.year}-${d.month.toString().padLeft(2,'0')}-01';
    final lastDay = DateTime(d.year, d.month + 1, 0).day;
    final to   = '${d.year}-${d.month.toString().padLeft(2,'0')}-${lastDay.toString().padLeft(2,'0')}';
    return _getTotalsInRange(from, to);
  }

  // 今年の activityId ごとの合計秒数
  static Future<Map<String, int>> getYearTotals([int? year]) async {
    final y = year ?? DateTime.now().year;
    final from = '$y-01-01';
    final to   = '$y-12-31';
    return _getTotalsInRange(from, to);
  }

  // 今週（月〜日）の DayData リストを返す（秒単位）
  static Future<List<DayData>> getWeekData([DateTime? baseDate]) async {
    final base = baseDate ?? DateTime.now();
    final weekStart = base.subtract(Duration(days: base.weekday - 1));
    const labels = ['月', '火', '水', '木', '金', '土', '日'];
    final result = <DayData>[];
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final records = await getByDate(_dateStr(day));
      final seconds = <String, int>{};
      for (final r in records) {
        seconds[r.activityId] = (seconds[r.activityId] ?? 0) + r.durationSeconds;
      }
      result.add(DayData(label: labels[i], minutes: seconds));
    }
    return result;
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}
