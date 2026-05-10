import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'models/activity.dart';
import 'models/sample_data.dart';
import 'screens/home_screen.dart';
import 'screens/tracker_screen.dart';
import 'screens/report_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/act_icon.dart';
import 'services/auth_service.dart';
import 'services/local_db.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('[main] Firebase init error: $e');
  }
  runApp(const TimeManagementApp());
}

class TimeManagementApp extends StatefulWidget {
  const TimeManagementApp({super.key});

  @override
  State<TimeManagementApp> createState() => _TimeManagementAppState();
}

class _TimeManagementAppState extends State<TimeManagementApp> {
  String _themeName = 'amber';
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemes.byName(_themeName);
    return MaterialApp(
      title: '行動時間管理',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: colors.bg,
      ),
      home: Stack(
        children: [
          AppShell(
            colors: colors,
            themeName: _themeName,
            onThemeChange: (name) => setState(() => _themeName = name),
          ),
          if (!_splashDone)
            SplashScreen(onDone: () => setState(() => _splashDone = true)),
        ],
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  final AppColors colors;
  final String themeName;
  final void Function(String) onThemeChange;

  const AppShell({
    super.key,
    required this.colors,
    required this.themeName,
    required this.onThemeChange,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;
  int _reportRefreshTrigger = 0;
  int _accountEpoch = 0; // 変化するとTrackerScreenが再マウントされる

  String? _activeId;
  Activity? _activeActivity;
  int _elapsed = 0;            // 今日の累積秒 + 今セッションの経過秒
  int _sessionStartElapsed = 0; // このセッション開始時点の _elapsed 値
  bool _paused = false;
  DateTime? _startTime;
  Timer? _timer;

  StreamSubscription<dynamic>? _authSub;
  String? _currentUid;

  @override
  void initState() {
    super.initState();
    _currentUid = AuthService.currentUser?.uid;
    _loadTodayData();
    _syncFromCloud();
    _authSub = AuthService.userStream.listen((user) {
      if (user?.uid != _currentUid) {
        _currentUid = user?.uid;
        _onAccountSwitch();
      }
    });
  }

  Future<void> _onAccountSwitch() async {
    // 計測中なら即停止
    _timer?.cancel();
    setState(() {
      _activeId = null;
      _activeActivity = null;
      _elapsed = 0;
      _sessionStartElapsed = 0;
      _paused = false;
      _startTime = null;
      _accountEpoch++;       // TrackerScreen を強制リマウント
      _reportRefreshTrigger++; // ReportScreen を強制リロード
      kTodayMin.clear();
      kWeekData.clear();
      kMonthData.clear();
    });
    // SQLite をクリアして新ユーザーのデータを取得
    await LocalDb.clearAll();
    await _syncFromCloud();
  }

  Future<void> _syncFromCloud() async {
    final count = await SyncService.downloadAndMerge();
    if (count > 0) _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    final results = await Future.wait([
      LocalDb.getTodayTotals(),
      LocalDb.getWeekData(),
      LocalDb.getMonthTotals(),
    ]);
    if (mounted) {
      setState(() {
        kTodayMin.clear();
        kTodayMin.addAll(results[0] as Map<String, int>);
        kWeekData.clear();
        kWeekData.addAll(results[1] as List<DayData>);
        kMonthData.clear();
        kMonthData.addAll(results[2] as Map<String, int>);
      });
    }
  }

  void _saveCurrentSession() {
    if (_activeId == null || _activeActivity == null) return;
    final sessionSecs = _elapsed - _sessionStartElapsed;
    if (sessionSecs < 1) return;
    final now = DateTime.now();
    kTodayMin[_activeId!] = _elapsed; // 累積値を即時反映
    final record = SessionRecord(
      activityId: _activeId!,
      activityLabel: _activeActivity!.label,
      durationSeconds: sessionSecs,
      date: '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}',
      startedAt: now.millisecondsSinceEpoch - (sessionSecs * 1000),
    );
    LocalDb.insert(record).then((_) async {
      await SyncService.uploadUnsynced();
      _loadTodayData();
    });
  }

  void _startOrSwitch(String id, Activity activity) {
    if (_activeId == id) return;
    _saveCurrentSession();
    _timer?.cancel();
    final now = DateTime.now();
    final accumulated = kTodayMin[id] ?? 0;
    setState(() {
      _activeId = id;
      _activeActivity = activity;
      _elapsed = accumulated;
      _sessionStartElapsed = accumulated;
      _paused = false;
      _startTime = now;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_paused) setState(() => _elapsed++);
    });
  }

  void _togglePause() => setState(() => _paused = !_paused);

  void _stop() {
    _saveCurrentSession();
    _timer?.cancel();
    setState(() {
      _activeId = null;
      _activeActivity = null;
      _elapsed = 0;
      _sessionStartElapsed = 0;
      _paused = false;
      _startTime = null;
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ));

    final screens = [
      HomeScreen(
        colors: c,
        activeId: _activeId,
        activeActivity: _activeActivity,
        elapsed: _elapsed,
        paused: _paused,
        onPause: _togglePause,
        onGoTracker: () => setState(() => _tab = 1),
        onGoReport: () => setState(() => _tab = 2),
        onGoSettings: () => setState(() => _tab = 3),
        onSelectActivity: (id) {
          _startOrSwitch(id, getActivity(id));
          setState(() => _tab = 1);
        },
      ),
      TrackerScreen(
        key: ValueKey('tracker_$_accountEpoch'),
        colors: c,
        activeId: _activeId,
        elapsed: _elapsed,
        paused: _paused,
        startTime: _startTime,
        onTap: _startOrSwitch,
        onPause: _togglePause,
        onStop: _stop,
      ),
      ReportScreen(colors: c, refreshTrigger: _reportRefreshTrigger),
      SettingsScreen(
        colors: c,
        themeName: widget.themeName,
        onThemeChange: widget.onThemeChange,
      ),
    ];

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          IndexedStack(index: _tab, children: screens),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _BottomTabBar(
              current: _tab,
              colors: c,
              onTap: (i) => setState(() {
                if (i == 2) _reportRefreshTrigger++;
                _tab = i;
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomTabBar extends StatelessWidget {
  final int current;
  final AppColors colors;
  final void Function(int) onTap;

  const _BottomTabBar({required this.current, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final tabs = [
      ('home', 'ホーム'),
      ('timer', '計測'),
      ('chart', 'レポート'),
      ('gear', '設定'),
    ];
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [c.bg, c.bg.withAlpha(0)],
          stops: const [0.6, 1.0],
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPad + 10),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: c.line),
          boxShadow: [
            BoxShadow(color: const Color(0xFF2A1E14).withAlpha(20), blurRadius: 30, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: tabs.asMap().entries.map((entry) {
            final i = entry.key;
            final t = entry.value;
            final active = current == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ActIcon(icon: t.$1, size: 22, color: active ? c.accent : c.inkMuted),
                    const SizedBox(height: 2),
                    Text(
                      t.$2,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: active ? c.accent : c.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
