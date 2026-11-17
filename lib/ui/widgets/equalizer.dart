import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated equalizer bars shown in the full-screen player.
///
/// Note: this is a visual indicator driven by the play state. just_audio does
/// not expose a real-time spectrum on Android without extra native code.
class EqualizerBars extends StatefulWidget {
  const EqualizerBars({super.key, required this.active, this.bars = 28, this.height = 56});

  final bool active;
  final int bars;
  final double height;

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  late final List<double> _phase;
  late final List<double> _speed;

  @override
  void initState() {
    super.initState();
    final r = math.Random(7);
    _phase = List.generate(widget.bars, (_) => r.nextDouble() * math.pi * 2);
    _speed = List.generate(widget.bars, (_) => 1 + r.nextInt(3).toDouble());
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(EqualizerBars old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(widget.bars, (i) {
            final level = widget.active
                ? 0.2 + 0.8 * math.sin(_c.value * math.pi * 2 * _speed[i] + _phase[i]).abs()
                : 0.12;
            return Container(
              width: 5,
              height: widget.height * level,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.55 + 0.45 * level),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ),
    );
  }
}
