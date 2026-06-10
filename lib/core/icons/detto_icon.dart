import 'package:flutter/material.dart';

/// Source of icon glyph. For MVP only material icons are used.
enum DettoIconSource { material }

/// Project icon wrapper. Convention: never use raw `Icon(Icons.xxx)` in views,
/// always go through DettoIcon so we can swap icon sets later.
class DettoIcon extends StatelessWidget {
  final IconData material;
  final DettoIconSource source;
  final double? size;
  final Color? color;

  const DettoIcon(
    this.material, {
    this.source = DettoIconSource.material,
    this.size,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) =>
      Icon(material, size: size, color: color);
}
