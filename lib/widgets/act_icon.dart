import 'dart:io';
import 'package:flutter/material.dart';

class ActIcon extends StatelessWidget {
  final String icon;
  final double size;
  final Color color;
  final String? imagePath;

  const ActIcon({super.key, required this.icon, this.size = 24, required this.color, this.imagePath});

  static const _icons = <String, IconData>{
    'briefcase': Icons.work_outline,
    'laptop':    Icons.laptop_mac,
    'gamepad':   Icons.sports_esports,
    'train':     Icons.train,
    'moon':      Icons.dark_mode,
    'dots':      Icons.more_horiz,
    'timer':     Icons.timer,
    'home':      Icons.home_outlined,
    'chart':     Icons.bar_chart,
    'gear':      Icons.settings,
    'play':      Icons.play_arrow,
    'pause':     Icons.pause,
    'stop':      Icons.stop,
    'plus':      Icons.add,
    'chevron':   Icons.chevron_right,
    'chevronL':  Icons.chevron_left,
    'edit':      Icons.edit_outlined,
    'trash':     Icons.delete_outline,
    'book':      Icons.menu_book,
    'run':       Icons.directions_run,
    'eat':       Icons.restaurant,
    'school':    Icons.school,
    'coffee':    Icons.coffee,
    'video':     Icons.movie,
    'music':     Icons.music_note,
    'camera':    Icons.camera_alt,
    'clean':     Icons.cleaning_services,
    'user':      Icons.person_outline,
    'arrow_right': Icons.arrow_forward_ios,
  };

  @override
  Widget build(BuildContext context) {
    if (imagePath != null) {
      return SizedBox(
        width: size * 1.4,
        height: size * 1.4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.3),
          child: Image.file(File(imagePath!), fit: BoxFit.cover),
        ),
      );
    }
    return Icon(_icons[icon] ?? Icons.circle_outlined, size: size, color: color);
  }
}
