import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/activity.dart';
import '../models/sample_data.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../widgets/act_icon.dart';

class TrackerScreen extends StatefulWidget {
  final AppColors colors;
  final String? activeId;
  final int elapsed;
  final bool paused;
  final DateTime? startTime;
  final void Function(String, Activity) onTap;
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
  List<String> _order = kActivities.map((a) => a.id).toList();
  final List<Activity> _customActivities = [];
  final Map<String, Activity> _overrides = {};
  final Map<String, Activity> _archived = {};
  int? _draggingIndex;
  int? _hoveredIndex;

  static const _kPrefUid       = 'activity_uid';
  static const _kPrefOrder     = 'activity_order';
  static const _kPrefCustom    = 'activity_custom';
  static const _kPrefOverrides = 'activity_overrides';
  static const _kPrefArchived  = 'activity_archived';

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUid = AuthService.currentUser?.uid;
    final savedUid = prefs.getString(_kPrefUid);
    final sameUser = currentUid != null && currentUid == savedUid;

    if (sameUser) {
      // 同じユーザー：SharedPreferences から即時ロード（高速・オフライン対応）
      if (mounted) {
        setState(() {
          _applyLocalPrefs(prefs);
          _syncGlobals();
        });
      }
    }
    // 別ユーザーまたは初回：SharedPreferences は汚染されている可能性があるためスキップ

    // Firestore から取得して上書き
    final remote = await SyncService.fetchActivities();
    if (!mounted) return;

    if (remote != null) {
      // Firestore にデータあり → 上書き適用
      setState(() {
        _applyRemoteData(remote);
        _syncGlobals();
      });
      await prefs.setString(_kPrefUid, currentUid ?? '');
      await _saveLocalPrefs();
    } else if (!sameUser) {
      // 別アカウント or 初回ログイン で Firestore にデータなし → デフォルトにリセット
      setState(() {
        _resetToDefaults();
        _syncGlobals();
      });
      await prefs.setString(_kPrefUid, currentUid ?? '');
      await _saveLocalPrefs();
    }
  }

  void _applyLocalPrefs(SharedPreferences prefs) {
    final orderList = prefs.getStringList(_kPrefOrder);
    final customList = prefs.getStringList(_kPrefCustom);
    final overridesStr = prefs.getString(_kPrefOverrides);
    final archivedStr = prefs.getString(_kPrefArchived);
    if (orderList != null) _order = orderList;
    if (customList != null) {
      _customActivities.clear();
      _customActivities.addAll(
        customList.map((s) => Activity.fromJson(jsonDecode(s) as Map<String, dynamic>)),
      );
    }
    if (overridesStr != null) {
      final map = jsonDecode(overridesStr) as Map<String, dynamic>;
      _overrides.clear();
      map.forEach((k, v) => _overrides[k] = Activity.fromJson(v as Map<String, dynamic>));
    }
    if (archivedStr != null) {
      final map = jsonDecode(archivedStr) as Map<String, dynamic>;
      _archived.clear();
      map.forEach((k, v) => _archived[k] = Activity.fromJson(v as Map<String, dynamic>));
    }
  }

  void _applyRemoteData(Map<String, dynamic> remote) {
    final remoteOrder = remote['order'];
    if (remoteOrder != null) _order = List<String>.from(remoteOrder as List);

    final remoteCustom = remote['custom'];
    if (remoteCustom != null) {
      _customActivities
        ..clear()
        ..addAll((remoteCustom as List).map(
          (m) => Activity.fromJson(Map<String, dynamic>.from(m as Map)),
        ));
    }

    final remoteOverrides = remote['overrides'];
    if (remoteOverrides != null) {
      _overrides.clear();
      (remoteOverrides as Map).forEach((k, v) =>
        _overrides[k as String] = Activity.fromJson(Map<String, dynamic>.from(v as Map)));
    }

    final remoteArchived = remote['archived'];
    if (remoteArchived != null) {
      _archived.clear();
      (remoteArchived as Map).forEach((k, v) =>
        _archived[k as String] = Activity.fromJson(Map<String, dynamic>.from(v as Map)));
    }
  }

  void _resetToDefaults() {
    _order = kActivities.map((a) => a.id).toList();
    _customActivities.clear();
    _overrides.clear();
    _archived.clear();
  }

  Future<void> _saveLocalPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefUid, AuthService.currentUser?.uid ?? '');
    await prefs.setStringList(_kPrefOrder, _order);
    await prefs.setStringList(_kPrefCustom, _customActivities.map((a) => jsonEncode(a.toJson())).toList());
    await prefs.setString(_kPrefOverrides, jsonEncode({for (final e in _overrides.entries) e.key: e.value.toJson()}));
    await prefs.setString(_kPrefArchived, jsonEncode({for (final e in _archived.entries) e.key: e.value.toJson()}));
  }

  void _syncGlobals() {
    kAllActivities
      ..clear()
      ..addAll(_order.map((id) {
        if (_overrides.containsKey(id)) return _overrides[id]!;
        final custom = _customActivities.where((a) => a.id == id).firstOrNull;
        if (custom != null) return custom;
        return kActivities.firstWhere((a) => a.id == id, orElse: () => kActivities.last);
      }));
    kArchivedActivities
      ..clear()
      ..addAll(_archived);
  }

  Future<void> _saveState() async {
    _syncGlobals();
    await _saveLocalPrefs();
    // Firestore にも非同期保存（ログイン済みの場合のみ・失敗しても継続）
    SyncService.saveActivities(
      order: _order,
      custom: _customActivities.map((a) => a.toJson()).toList(),
      overrides: {for (final e in _overrides.entries) e.key: e.value.toJson()},
      archived: {for (final e in _archived.entries) e.key: e.value.toJson()},
    );
  }

  Activity _getActivity(String id) {
    if (_overrides.containsKey(id)) return _overrides[id]!;
    return _customActivities.firstWhere((a) => a.id == id, orElse: () => getActivity(id));
  }

  Set<String> _existingLabelsExcluding(String? excludeLabel) => {
    ...kActivities.map((a) => a.label),
    ..._customActivities.map((a) => a.label),
    ..._overrides.values.map((a) => a.label),
  }..remove(excludeLabel);

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActivityFormSheet(
        colors: widget.colors,
        existingLabels: _existingLabelsExcluding(null),
        archivedByLabel: { for (final e in _archived.entries) e.value.label: e.value },
        onSave: (act) { setState(() { _customActivities.add(act); _order.add(act.id); }); _saveState(); },
        onRestore: (archived) {
          setState(() {
            _archived.remove(archived.id);
            _order.add(archived.id);
            if (archived.id.startsWith('custom_')) {
              _customActivities.add(archived);
            } else {
              _overrides[archived.id] = archived;
            }
          });
          _saveState();
        },
      ),
    );
  }

  void _showEditSheet(String id) {
    final act = _getActivity(id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActivityFormSheet(
        colors: widget.colors,
        existingLabels: _existingLabelsExcluding(act.label),
        editing: act,
        onSave: (updated) {
          setState(() {
            final isCustom = _customActivities.any((a) => a.id == id);
            if (isCustom) {
              final i = _customActivities.indexWhere((a) => a.id == id);
              _customActivities[i] = updated;
            } else {
              _overrides[id] = updated;
            }
          });
          _saveState();
        },
        onDelete: (delId) {
          setState(() {
            _archived[delId] = act; // 論理削除：メタデータを保持
            _order.remove(delId);
            _customActivities.removeWhere((a) => a.id == delId);
            _overrides.remove(delId);
          });
          _saveState();
        },
      ),
    );
  }

  void _reorder(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;
    setState(() {
      final item = _order.removeAt(fromIndex);
      _order.insert(toIndex, item);
    });
    _saveState();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final screenWidth = MediaQuery.of(context).size.width;
    final tileWidth = (screenWidth - 32 - 10 * (_cols - 1)) / _cols;
    final tileHeight = tileWidth / (_cols == 2 ? 1.2 : 1.05);

    return SingleChildScrollView(
      physics: _draggingIndex != null ? const NeverScrollableScrollPhysics() : null,
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
                              child: Center(child: Icon(n == 2 ? Icons.grid_view : Icons.apps, size: 18, color: active ? c.ink : c.inkMuted)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() { _editing = !_editing; _draggingIndex = null; _hoveredIndex = null; }),
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
                          child: Text(_editing ? '完了' : '編集', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _editing ? c.bg : c.ink)),
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
            activeId: widget.activeId, elapsed: widget.elapsed, paused: widget.paused,
            startTime: widget.startTime, onPause: widget.onPause, onStop: widget.onStop, colors: c,
            resolveActivity: _getActivity,
          ),

          if (widget.activeId == null && !_editing)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('タイルをタップで計測開始・別タイルをタップで即切替', style: TextStyle(fontSize: 12, color: c.inkMuted)),
            ),

          if (_editing)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('長押しで並び替え・タップで編集', style: TextStyle(fontSize: 12, color: c.inkMuted)),
            ),

          // Activity grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (int index = 0; index < _order.length; index++)
                  _buildTile(index, tileWidth, tileHeight, c),
                SizedBox(
                  width: tileWidth, height: tileHeight,
                  child: _AddTile(colors: c, onTap: _showCreateSheet),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(int index, double tileWidth, double tileHeight, AppColors c) {
    final id = _order[index];
    final act = _getActivity(id);
    final isActive = widget.activeId == id;
    final isHovered = _hoveredIndex == index && _draggingIndex != index;

    final tile = SizedBox(
      width: tileWidth, height: tileHeight,
      child: _ActivityTile(
        act: act,
        isActive: isActive && !_editing,
        elapsed: isActive ? widget.elapsed : 0,
        todayMin: kTodayMin[id] ?? 0,
        editing: _editing,
        colors: c,
        isDragTarget: isHovered,
        onTap: () {
          if (_editing) { _showEditSheet(id); }
          else { widget.onTap(id, act); }
        },
        onRemove: () {
          final act = _getActivity(id);
          setState(() {
            _archived[id] = act; // 論理削除：メタデータを保持
            _order.remove(id);
            _customActivities.removeWhere((a) => a.id == id);
          });
          _saveState();
        },
      ),
    );

    if (!_editing) return tile;

    return LongPressDraggable<int>(
      data: index,
      delay: const Duration(milliseconds: 350),
      onDragStarted: () => setState(() => _draggingIndex = index),
      onDragEnd: (_) => setState(() { _draggingIndex = null; _hoveredIndex = null; }),
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.9, child: tile),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: tile),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (d) => d.data != index,
        onMove: (details) {
          if (_hoveredIndex != index) setState(() => _hoveredIndex = index);
        },
        onAcceptWithDetails: (d) {
          _reorder(d.data, index);
          setState(() { _draggingIndex = null; _hoveredIndex = null; });
        },
        onLeave: (_) {
          if (_hoveredIndex == index) setState(() => _hoveredIndex = null);
        },
        builder: (ctx, candidates, rejected) => tile,
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
  final Activity Function(String) resolveActivity;

  const _LiveTimerBar({
    required this.activeId, required this.elapsed, required this.paused,
    this.startTime, required this.onPause, required this.onStop, required this.colors,
    required this.resolveActivity,
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

    final act = resolveActivity(activeId!);
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
                child: Center(child: ActIcon(icon: act.icon, size: 22, color: Colors.white, imagePath: act.imagePath)),
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
  final bool isDragTarget;
  final AppColors colors;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ActivityTile({
    required this.act, required this.isActive, required this.elapsed,
    required this.todayMin, required this.editing, required this.colors,
    required this.onTap, required this.onRemove, this.isDragTarget = false,
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
              color: isDragTarget ? act.color.withAlpha(20) : bg,
              borderRadius: BorderRadius.circular(22),
              border: isDragTarget ? Border.all(color: act.color, width: 2) : null,
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
                      child: Center(child: ActIcon(icon: act.icon, size: 22, color: isActive ? Colors.white : act.color, imagePath: act.imagePath)),
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
                  editing ? 'タップで編集' : (isActive ? fmtClock(elapsed) : (todayMin > 0 ? '今日 ${fmtHMSShort(todayMin)}' : '—')),
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

// ── Create Activity Sheet ────────────────────────────────────

const _kIconChoices = ['briefcase', 'laptop', 'gamepad', 'train', 'moon', 'book', 'run', 'eat', 'school', 'coffee', 'video', 'music', 'camera', 'clean', 'dots'];
const _kColorChoices = [
  Color(0xFFB3541B), Color(0xFFC2410C), Color(0xFF8A6A2E), Color(0xFF7A6A1F),
  Color(0xFFA04668), Color(0xFF4A6B52), Color(0xFF3D5A80), Color(0xFF6B5A4B),
  Color(0xFFA0522D), Color(0xFF9A3F3F),
];

class _ActivityFormSheet extends StatefulWidget {
  final AppColors colors;
  final Set<String> existingLabels;
  final Map<String, Activity> archivedByLabel;
  final void Function(Activity) onSave;
  final void Function(Activity)? onRestore;
  final Activity? editing;
  final void Function(String)? onDelete;

  const _ActivityFormSheet({
    required this.colors,
    required this.existingLabels,
    this.archivedByLabel = const {},
    required this.onSave,
    this.onRestore,
    this.editing,
    this.onDelete,
  });

  @override
  State<_ActivityFormSheet> createState() => _ActivityFormSheetState();
}

class _ActivityFormSheetState extends State<_ActivityFormSheet> {
  late final TextEditingController _nameController;
  final _hexController = TextEditingController();
  late String _icon;
  late Color _color;
  String? _imagePath;
  String? _nameError;
  bool _customColorOpen = false;
  String? _hexError;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _nameController = TextEditingController(text: e?.label ?? '新規');
    _icon = e?.icon ?? 'briefcase';
    _color = e?.color ?? _kColorChoices[0];
    _imagePath = e?.imagePath;
  }

  Color _tintFrom(Color c) => c.withAlpha(51);

  String _colorToHex(Color col) {
    final r = (col.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (col.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (col.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  void _applyColor(Color col) {
    setState(() => _color = col);
    _hexController.text = _colorToHex(col);
    _hexController.selection = TextSelection.fromPosition(
      TextPosition(offset: _hexController.text.length),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _imagePath = picked.path);
  }

  void _clearImage() => setState(() => _imagePath = null);

  void _onHexChanged(String raw) {
    final hex = raw.replaceAll('#', '');
    if (hex.length == 6) {
      try {
        final color = Color(int.parse('FF$hex', radix: 16));
        setState(() { _color = color; _hexError = null; });
        return;
      } catch (_) {}
    }
    if (hex.isNotEmpty) {
      setState(() => _hexError = '有効な6桁HEXを入力');
    } else {
      setState(() => _hexError = null);
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = '名前を入力してください');
      return;
    }
    if (widget.existingLabels.contains(name)) {
      setState(() => _nameError = '「$name」はすでに存在します');
      return;
    }

    // 論理削除済みアクティビティと同名の場合は復元を提案
    final archivedMatch = widget.archivedByLabel[name];
    if (archivedMatch != null && widget.onRestore != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text('「$name」を復元しますか？'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // アーカイブ済みアクティビティのプレビュー
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: archivedMatch.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: ActIcon(icon: archivedMatch.icon, size: 22, color: Colors.white, imagePath: archivedMatch.imagePath),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(archivedMatch.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: archivedMatch.color, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text('アイコン・カラーも引き継がれます', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('復元すると過去の記録も含めて引き継がれます。', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
                widget.onRestore!(archivedMatch);
              },
              child: const Text('復元する'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                final act = Activity(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  label: name,
                  color: _color,
                  tint: _tintFrom(_color),
                  icon: _icon,
                  imagePath: _imagePath,
                );
                widget.onSave(act);
                Navigator.of(context).pop();
              },
              child: const Text('新しく作る'),
            ),
          ],
        ),
      );
      return;
    }

    final e = widget.editing;
    final act = Activity(
      id: e?.id ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
      label: name,
      color: _color,
      tint: _tintFrom(_color),
      icon: _icon,
      imagePath: _imagePath,
    );
    widget.onSave(act);
    Navigator.of(context).pop();
  }

  void _delete() {
    final id = widget.editing?.id;
    if (id == null) return;
    Navigator.of(context).pop();
    widget.onDelete?.call(id);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPad),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ハンドル
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36, height: 4,
              decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(2)),
            ),
            // タイトル行
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text('キャンセル', style: TextStyle(fontSize: 15, color: c.inkMuted)),
                  ),
                  const Spacer(),
                  Text(widget.editing != null ? 'アクティビティを編集' : '新規アクティビティ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.ink)),
                  const Spacer(),
                  const SizedBox(width: 60),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // プレビュー
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: _imagePath != null ? Colors.black : _color,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _imagePath != null
                      ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                      : Center(child: ActIcon(icon: _icon, size: 36, color: Colors.white)),
                ),
                if (_imagePath != null)
                  GestureDetector(
                    onTap: _clearImage,
                    child: Container(
                      width: 24, height: 24,
                      decoration: const BoxDecoration(color: Color(0xFFE11D48), shape: BoxShape.circle),
                      child: const Center(child: Icon(Icons.close, size: 14, color: Colors.white)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // 名前入力
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(14),
                      border: _nameError != null ? Border.all(color: Colors.red.shade400, width: 1.5) : null,
                    ),
                    child: Row(
                      children: [
                        Text('名前', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.inkMuted)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.ink),
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                            autofocus: true,
                            onChanged: (_) { if (_nameError != null) setState(() => _nameError = null); },
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_nameError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(_nameError!, style: TextStyle(fontSize: 12, color: Colors.red.shade400)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // アイコン選択
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('アイコン', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.inkMuted)),
                        const Spacer(),
                        if (_imagePath != null)
                          GestureDetector(
                            onTap: _clearImage,
                            child: Text('画像を外す', style: TextStyle(fontSize: 12, color: c.accent, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 画像アップロードタイル
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _imagePath != null ? _color.withAlpha(20) : c.bgDeep,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _imagePath != null ? _color : c.line,
                            width: _imagePath != null ? 1.5 : 1,
                            style: _imagePath != null ? BorderStyle.solid : BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: _imagePath != null ? Colors.transparent : c.card,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: _imagePath != null
                                  ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                                  : Center(child: Icon(Icons.add_photo_alternate_outlined, size: 20, color: c.inkMuted)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _imagePath != null ? '画像を変更' : '画像を選択',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                                  ),
                                  Text('PNG / JPG · 正方形推奨', style: TextStyle(fontSize: 11, color: c.inkMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 区切り
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: c.line, height: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('または', style: TextStyle(fontSize: 11, color: c.inkMuted, fontWeight: FontWeight.w600)),
                          ),
                          Expanded(child: Divider(color: c.line, height: 1)),
                        ],
                      ),
                    ),
                    // シンボルグリッド
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: _kIconChoices.map((ico) {
                        final selected = _imagePath == null && _icon == ico;
                        return GestureDetector(
                          onTap: () => setState(() { _icon = ico; _imagePath = null; }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            width: 46, height: 46,
                            decoration: BoxDecoration(
                              color: selected ? _color.withAlpha(30) : c.bgDeep,
                              borderRadius: BorderRadius.circular(13),
                              border: selected ? Border.all(color: _color, width: 2) : null,
                            ),
                            child: Center(child: ActIcon(icon: ico, size: 22, color: selected ? _color : c.inkMuted)),
                          ),
                        );
                      }).toList(),
                    ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // カラー選択
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('カラー', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.inkMuted)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _customColorOpen = !_customColorOpen),
                          child: Text(
                            _customColorOpen ? '閉じる' : 'その他…',
                            style: TextStyle(fontSize: 12, color: c.accent, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // プリセット + カスタムボタン
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ..._kColorChoices.map((col) {
                          final selected = !_customColorOpen && _color == col;
                          return GestureDetector(
                            onTap: () { _applyColor(col); setState(() => _customColorOpen = false); },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: col,
                                shape: BoxShape.circle,
                                border: selected ? Border.all(color: c.ink, width: 3) : null,
                                boxShadow: selected ? [BoxShadow(color: col.withAlpha(100), blurRadius: 8)] : null,
                              ),
                            ),
                          );
                        }),
                        // カラーホイールボタン
                        Builder(builder: (ctx) {
                          final isCustom = !_kColorChoices.contains(_color);
                          return GestureDetector(
                            onTap: () => setState(() => _customColorOpen = !_customColorOpen),
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const SweepGradient(colors: [
                                  Color(0xFFFF0000), Color(0xFFFF8000), Color(0xFFFFFF00),
                                  Color(0xFF00FF00), Color(0xFF00FFFF), Color(0xFF0000FF),
                                  Color(0xFFFF00FF), Color(0xFFFF0000),
                                ]),
                                border: (_customColorOpen || isCustom)
                                    ? Border.all(color: c.ink, width: 3)
                                    : Border.all(color: c.line),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    // カスタムカラーパネル
                    if (_customColorOpen) ...[
                      const SizedBox(height: 14),
                      Divider(color: c.line, height: 1),
                      const SizedBox(height: 14),
                      // HEX入力
                      Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(color: _color, borderRadius: BorderRadius.circular(12)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('HEX', style: TextStyle(fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w700, color: c.inkMuted)),
                                TextField(
                                  controller: _hexController,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.ink, fontFamily: 'monospace'),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    hintText: '#B3541B',
                                    hintStyle: TextStyle(color: c.inkMuted),
                                  ),
                                  onChanged: _onHexChanged,
                                ),
                                if (_hexError != null)
                                  Text(_hexError!, style: const TextStyle(fontSize: 11, color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 明度スライダー
                      _HueSlider(
                        color: _color,
                        onChanged: _applyColor,
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => setState(() => _customColorOpen = false),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text('このカラーを適用', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // 保存ボタン
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: GestureDetector(
                onTap: _save,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      widget.editing != null ? '変更を保存' : 'アクティビティを追加',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.editing != null && widget.onDelete != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: GestureDetector(
                  onTap: _delete,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48).withAlpha(12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE11D48).withAlpha(60)),
                    ),
                    child: const Center(
                      child: Text('削除', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFE11D48))),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _HueSlider extends StatelessWidget {
  final Color color;
  final void Function(Color) onChanged;
  const _HueSlider({required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final hsv = HSVColor.fromColor(color);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 色相
        _GradientSlider(
          label: '色相',
          value: hsv.hue / 360,
          gradient: const LinearGradient(colors: [
            Color(0xFFFF0000), Color(0xFFFFFF00), Color(0xFF00FF00),
            Color(0xFF00FFFF), Color(0xFF0000FF), Color(0xFFFF00FF), Color(0xFFFF0000),
          ]),
          onChanged: (v) => onChanged(HSVColor.fromAHSV(hsv.alpha, v * 360, hsv.saturation, hsv.value).toColor()),
        ),
        const SizedBox(height: 10),
        // 彩度
        _GradientSlider(
          label: '彩度',
          value: hsv.saturation,
          gradient: LinearGradient(colors: [Colors.white, HSVColor.fromAHSV(1, hsv.hue, 1, hsv.value).toColor()]),
          onChanged: (v) => onChanged(HSVColor.fromAHSV(hsv.alpha, hsv.hue, v, hsv.value).toColor()),
        ),
        const SizedBox(height: 10),
        // 明度
        _GradientSlider(
          label: '明度',
          value: hsv.value,
          gradient: LinearGradient(colors: [Colors.black, HSVColor.fromAHSV(1, hsv.hue, hsv.saturation, 1).toColor()]),
          onChanged: (v) => onChanged(HSVColor.fromAHSV(hsv.alpha, hsv.hue, hsv.saturation, v).toColor()),
        ),
      ],
    );
  }
}

class _GradientSlider extends StatelessWidget {
  final String label;
  final double value;
  final LinearGradient gradient;
  final void Function(double) onChanged;
  const _GradientSlider({required this.label, required this.value, required this.gradient, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 28, child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0x886B5A4B)))),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 12,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              trackShape: _GradientTrackShape(gradient: gradient),
            ),
            child: Slider(
              value: value.clamp(0.0, 1.0),
              onChanged: onChanged,
              activeColor: Colors.transparent,
              inactiveColor: Colors.transparent,
              thumbColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientTrackShape extends SliderTrackShape {
  final LinearGradient gradient;
  const _GradientTrackShape({required this.gradient});

  @override
  Rect getPreferredRect({required RenderBox parentBox, Offset offset = Offset.zero,
      required SliderThemeData sliderTheme, bool isEnabled = false, bool isDiscrete = false}) {
    const trackHeight = 12.0;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(offset.dx + 10, trackTop, parentBox.size.width - 20, trackHeight);
  }

  @override
  void paint(PaintingContext context, Offset offset, {required RenderBox parentBox,
      required SliderThemeData sliderTheme, required Animation<double> enableAnimation,
      required Offset thumbCenter, Offset? secondaryOffset, bool isEnabled = false,
      bool isDiscrete = false, required TextDirection textDirection}) {
    final rect = getPreferredRect(parentBox: parentBox, offset: offset, sliderTheme: sliderTheme);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    final paint = Paint()..shader = gradient.createShader(rect);
    context.canvas.drawRRect(rRect, paint);
  }
}
