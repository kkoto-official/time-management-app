import 'package:flutter/material.dart';

class Activity {
  final String id;
  final String label;
  final Color color;
  final Color tint;
  final String icon;
  final String? imagePath;

  const Activity({
    required this.id,
    required this.label,
    required this.color,
    required this.tint,
    required this.icon,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'color': color.value,
    'tint': tint.value,
    'icon': icon,
    if (imagePath != null) 'imagePath': imagePath,
  };

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
    id: json['id'] as String,
    label: json['label'] as String,
    color: Color(json['color'] as int),
    tint: Color(json['tint'] as int),
    icon: json['icon'] as String,
    imagePath: json['imagePath'] as String?,
  );

  Activity copyWith({String? label, Color? color, Color? tint, String? icon, String? imagePath}) {
    return Activity(
      id: id,
      label: label ?? this.label,
      color: color ?? this.color,
      tint: tint ?? this.tint,
      icon: icon ?? this.icon,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

class TimelineSegment {
  final String start;
  final String end;
  final String actId;

  const TimelineSegment({required this.start, required this.end, required this.actId});

  int get startMin {
    final parts = start.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int get endMin {
    final parts = end.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int get durationMin => endMin - startMin;
}

class DayData {
  final String label;
  final Map<String, int> minutes;

  const DayData({required this.label, required this.minutes});
}

String fmtHMSShort(int sec) {
  final h = sec ~/ 3600;
  final m = (sec % 3600) ~/ 60;
  final s = sec % 60;
  if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
  if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
  return '${s}s';
}

String fmtHMShort(int min) {
  final h = min ~/ 60;
  final m = min % 60;
  if (h == 0) return '${m}m';
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}

String fmtHM(int min) {
  final h = min ~/ 60;
  final m = min % 60;
  if (h == 0) return '$m分';
  if (m == 0) return '$h時間';
  return '$h時間$m分';
}

String fmtClock(int sec) {
  final h = sec ~/ 3600;
  final m = (sec % 3600) ~/ 60;
  final s = sec % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
