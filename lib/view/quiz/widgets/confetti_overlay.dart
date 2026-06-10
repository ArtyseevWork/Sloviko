import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

class ConfettiOverlay extends StatefulWidget {
  final bool active;
  const ConfettiOverlay({required this.active, super.key});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> {
  late final ConfettiController _ctrl =
      ConfettiController(duration: const Duration(milliseconds: 1800));

  @override
  void didUpdateWidget(covariant ConfettiOverlay old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _ctrl.play();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _ctrl,
          blastDirection: pi / 2, // down
          blastDirectionality: BlastDirectionality.explosive,
          maxBlastForce: 18,
          minBlastForce: 6,
          emissionFrequency: 0.06,
          numberOfParticles: 26,
          gravity: 0.25,
          shouldLoop: false,
          colors: const [
            Color(0xFF2F7DE0),
            Color(0xFF1A8742),
            Color(0xFFE0A82F),
            Color(0xFF8A4FE0),
            Color(0xFF2FB5C2),
            Color(0xFFD63D2E),
          ],
        ),
      ),
    );
  }
}
