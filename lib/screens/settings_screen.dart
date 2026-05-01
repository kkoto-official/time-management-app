import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  final AppColors colors;
  final String themeName;
  final void Function(String) onThemeChange;

  const SettingsScreen({
    super.key,
    required this.colors,
    required this.themeName,
    required this.onThemeChange,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text('設定', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: c.ink, letterSpacing: -0.8)),
          ),

          _SectionLabel(label: '外観', colors: c),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('テーマ', style: TextStyle(fontSize: 15, color: c.ink, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _ThemeChip(themeKey: 'amber', label: 'Amber', themeName: themeName, onTap: onThemeChange),
                      const SizedBox(width: 8),
                      _ThemeChip(themeKey: 'terracotta', label: 'Terra', themeName: themeName, onTap: onThemeChange),
                      const SizedBox(width: 8),
                      _ThemeChip(themeKey: 'olive', label: 'Olive', themeName: themeName, onTap: onThemeChange),
                    ],
                  ),
                  Divider(color: c.line, height: 24),
                  _SettingsRow(label: 'ダークモード', value: 'システム', colors: c, last: true),
                ],
              ),
            ),
          ),

          _SectionLabel(label: '計測', colors: c),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _SettingsRow(label: '自動一時停止', value: '5分後', colors: c),
                  _SettingsRow(label: 'アイドル検知', value: 'オン', colors: c),
                  _SettingsRow(label: 'ロック画面ウィジェット', value: '許可', colors: c, last: true),
                ],
              ),
            ),
          ),

          _SectionLabel(label: 'データ', colors: c),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _SettingsRow(label: 'エクスポート', value: 'CSV · JSON', colors: c),
                  _SettingsRow(label: 'バックアップ', value: 'iCloud', colors: c, last: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final AppColors colors;
  const _SectionLabel({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      child: Text(label.toUpperCase(), style: TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w700, color: colors.inkMuted)),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final String value;
  final AppColors colors;
  final bool last;

  const _SettingsRow({required this.label, required this.value, required this.colors, this.last = false});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: c.line))),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 15, color: c.ink, fontWeight: FontWeight.w500))),
          Text(value, style: TextStyle(fontSize: 14, color: c.inkMuted)),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, size: 16, color: c.inkSubtle),
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String themeKey;
  final String label;
  final String themeName;
  final void Function(String) onTap;

  const _ThemeChip({required this.themeKey, required this.label, required this.themeName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppThemes.byName(themeKey);
    final active = themeName == themeKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(themeKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: t.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? t.accent : t.line, width: active ? 2 : 1),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 14, height: 14, decoration: BoxDecoration(color: t.accent, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 4),
                  Container(width: 14, height: 14, decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(3), border: Border.all(color: t.line))),
                  const SizedBox(width: 4),
                  Container(width: 14, height: 14, decoration: BoxDecoration(color: t.ink, borderRadius: BorderRadius.circular(3))),
                ],
              ),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.ink)),
            ],
          ),
        ),
      ),
    );
  }
}
