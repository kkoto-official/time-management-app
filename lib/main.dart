import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/tracker_screen.dart';
import 'screens/report_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/act_icon.dart';

void main() {
  runApp(const TimeManagementApp());
}

class TimeManagementApp extends StatefulWidget {
  const TimeManagementApp({super.key});

  @override
  State<TimeManagementApp> createState() => _TimeManagementAppState();
}

class _TimeManagementAppState extends State<TimeManagementApp> {
  String _themeName = 'amber';

  @override
  Widget build(BuildContext context) {
    final colors = AppThemes.byName(_themeName);
    return MaterialApp(
      title: '行動時間管理',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: colors.bg,
      ),
      home: AppShell(
        colors: colors,
        themeName: _themeName,
        onThemeChange: (name) => setState(() => _themeName = name),
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

  String? _activeId;
  int _elapsed = 0;
  bool _paused = false;
  DateTime? _startTime;
  Timer? _timer;

  void _startOrSwitch(String id) {
    if (_activeId == id) return;
    _timer?.cancel();
    final now = DateTime.now();
    setState(() {
      _activeId = id;
      _elapsed = 0;
      _paused = false;
      _startTime = now;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_paused) setState(() => _elapsed++);
    });
  }

  void _togglePause() => setState(() => _paused = !_paused);

  void _stop() {
    _timer?.cancel();
    setState(() { _activeId = null; _elapsed = 0; _paused = false; _startTime = null; });
  }

  @override
  void dispose() {
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
        elapsed: _elapsed,
        paused: _paused,
        onPause: _togglePause,
        onGoTracker: () => setState(() => _tab = 1),
        onGoSettings: () => setState(() => _tab = 3),
        onSelectActivity: (_) => setState(() => _tab = 1),
      ),
      TrackerScreen(
        colors: c,
        activeId: _activeId,
        elapsed: _elapsed,
        paused: _paused,
        startTime: _startTime,
        onTap: _startOrSwitch,
        onPause: _togglePause,
        onStop: _stop,
      ),
      ReportScreen(colors: c),
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
              onTap: (i) => setState(() => _tab = i),
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
