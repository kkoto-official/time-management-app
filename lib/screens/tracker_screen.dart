import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final List<Activity> _customActivities = [];

  Activity _getActivity(String id) {
    return _customActivities.firstWhere(
      (a) => a.id == id,
      orElse: () => getActivity(id),
    );
  }

  Set<String> get _existingLabels => {
    ...kActivities.map((a) => a.label),
    ..._customActivities.map((a) => a.label),
  };

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateActivitySheet(
        colors: widget.colors,
        existingLabels: _existingLabels,
        onSave: (act) {
          setState(() {
            _customActivities.add(act);
            _order.add(act.id);
          });
        },
      ),
    );
  }

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
                  return _AddTile(colors: c, onTap: _showCreateSheet);
                }
                final id = _order[index];
                final act = _getActivity(id);
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

// ── Create Activity Sheet ────────────────────────────────────

const _kIconChoices = ['briefcase', 'laptop', 'gamepad', 'train', 'moon', 'book', 'dots', 'plus', 'chart', 'timer'];
const _kColorChoices = [
  Color(0xFFB3541B), Color(0xFFC2410C), Color(0xFF8A6A2E), Color(0xFF7A6A1F),
  Color(0xFFA04668), Color(0xFF4A6B52), Color(0xFF3D5A80), Color(0xFF6B5A4B),
  Color(0xFFA0522D), Color(0xFF9A3F3F),
];

class _CreateActivitySheet extends StatefulWidget {
  final AppColors colors;
  final Set<String> existingLabels;
  final void Function(Activity) onSave;

  const _CreateActivitySheet({required this.colors, required this.existingLabels, required this.onSave});

  @override
  State<_CreateActivitySheet> createState() => _CreateActivitySheetState();
}

class _CreateActivitySheetState extends State<_CreateActivitySheet> {
  final _nameController = TextEditingController(text: '新規');
  final _hexController = TextEditingController();
  String _icon = 'briefcase';
  Color _color = _kColorChoices[0];
  String? _imagePath;
  String? _nameError;
  bool _customColorOpen = false;
  String? _hexError;

  Color _tintFrom(Color c) => c.withAlpha(51);

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
    if (hex.isNotEmpty) setState(() => _hexError = '有効な6桁HEXを入力');
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
                  Text('新規アクティビティ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.ink)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _save,
                    child: Text('追加', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.accent)),
                  ),
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
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
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
                          final selected = !_customColorOpen && _color == col && !_kColorChoices.every((c2) => c2 != _color) ? _color == col : _color == col;
                          return GestureDetector(
                            onTap: () => setState(() { _color = col; _customColorOpen = false; }),
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
                        GestureDetector(
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
                              border: _customColorOpen ? Border.all(color: c.ink, width: 3) : Border.all(color: c.line),
                            ),
                          ),
                        ),
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
                        onChanged: (col) => setState(() => _color = col),
                      ),
                    ],
                  ],
                ),
              ),
            ),
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
