import 'package:flutter/material.dart';
import 'activity.dart';

const kActivities = [
  Activity(id: 'workA', label: '仕事A', color: Color(0xFFB3541B), tint: Color(0xFFF8D9C0), icon: 'briefcase'),
  Activity(id: 'workB', label: '仕事B', color: Color(0xFF8A6A2E), tint: Color(0xFFEFE1C3), icon: 'laptop'),
  Activity(id: 'game',  label: 'ゲーム', color: Color(0xFFA04668), tint: Color(0xFFF4D4DE), icon: 'gamepad'),
  Activity(id: 'move',  label: '移動',  color: Color(0xFF4A6B52), tint: Color(0xFFD7E4D8), icon: 'train'),
  Activity(id: 'sleep',    label: '睡眠',  color: Color(0xFF3D5A80), tint: Color(0xFFD3DDEA), icon: 'moon'),
  Activity(id: 'exercise', label: '運動',  color: Color(0xFF2E6E5A), tint: Color(0xFFC0DDD8), icon: 'run'),
  Activity(id: 'meal',     label: '食事',  color: Color(0xFF7A4E28), tint: Color(0xFFEDD9C8), icon: 'eat'),
  Activity(id: 'other',    label: 'その他', color: Color(0xFF6B5A4B), tint: Color(0xFFE2D8CD), icon: 'dots'),
];

// 起動時に LocalDb から読み込んで上書きされる（秒単位）
final kTodayMin = <String, int>{};
final kWeekData = <DayData>[];
final kMonthData = <String, int>{};
final kTimeline = <TimelineSegment>[];

Activity getActivity(String id) {
  return kActivities.firstWhere((a) => a.id == id, orElse: () => kActivities.last);
}
