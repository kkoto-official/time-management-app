import 'package:flutter/material.dart';
import 'activity.dart';

const kActivities = [
  Activity(id: 'workA', label: '仕事A', color: Color(0xFFB3541B), tint: Color(0xFFF8D9C0), icon: 'briefcase'),
  Activity(id: 'workB', label: '仕事B', color: Color(0xFF8A6A2E), tint: Color(0xFFEFE1C3), icon: 'laptop'),
  Activity(id: 'game',  label: 'ゲーム', color: Color(0xFFA04668), tint: Color(0xFFF4D4DE), icon: 'gamepad'),
  Activity(id: 'move',  label: '移動',  color: Color(0xFF4A6B52), tint: Color(0xFFD7E4D8), icon: 'train'),
  Activity(id: 'sleep', label: '睡眠',  color: Color(0xFF3D5A80), tint: Color(0xFFD3DDEA), icon: 'moon'),
  Activity(id: 'other', label: 'その他', color: Color(0xFF6B5A4B), tint: Color(0xFFE2D8CD), icon: 'dots'),
];

const kTodayMin = {
  'workA': 218,
  'workB': 74,
  'game':  52,
  'move':  43,
  'sleep': 0,
  'other': 28,
};

const kWeekData = [
  DayData(label: '月', minutes: {'workA': 380, 'workB': 110, 'game': 30,  'move': 80, 'sleep': 420, 'other': 40}),
  DayData(label: '火', minutes: {'workA': 420, 'workB': 60,  'game': 45,  'move': 70, 'sleep': 440, 'other': 25}),
  DayData(label: '水', minutes: {'workA': 360, 'workB': 140, 'game': 90,  'move': 60, 'sleep': 390, 'other': 55}),
  DayData(label: '木', minutes: {'workA': 400, 'workB': 90,  'game': 20,  'move': 85, 'sleep': 430, 'other': 30}),
  DayData(label: '金', minutes: {'workA': 340, 'workB': 180, 'game': 120, 'move': 95, 'sleep': 400, 'other': 45}),
  DayData(label: '土', minutes: {'workA': 90,  'workB': 40,  'game': 240, 'move': 60, 'sleep': 500, 'other': 80}),
  DayData(label: '日', minutes: {'workA': 218, 'workB': 74,  'game': 52,  'move': 43, 'sleep': 0,   'other': 28}),
];

const kTimeline = [
  TimelineSegment(start: '06:40', end: '07:12', actId: 'other'),
  TimelineSegment(start: '07:12', end: '07:48', actId: 'move'),
  TimelineSegment(start: '07:48', end: '10:04', actId: 'workA'),
  TimelineSegment(start: '10:04', end: '10:20', actId: 'other'),
  TimelineSegment(start: '10:20', end: '12:02', actId: 'workA'),
  TimelineSegment(start: '12:02', end: '12:44', actId: 'other'),
  TimelineSegment(start: '12:44', end: '13:18', actId: 'move'),
  TimelineSegment(start: '13:18', end: '14:36', actId: 'workB'),
  TimelineSegment(start: '14:36', end: '15:28', actId: 'game'),
  TimelineSegment(start: '15:28', end: '16:22', actId: 'workA'),
];

Activity getActivity(String id) {
  return kActivities.firstWhere((a) => a.id == id, orElse: () => kActivities.last);
}
