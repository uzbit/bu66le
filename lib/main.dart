import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() => runApp(const BubbleApp());

class BubbleApp extends StatelessWidget {
  const BubbleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'bu66le',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0E1116),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF35D07F)),
        fontFamily: 'monospace',
      ),
      home: const LevelPage(),
    );
  }
}

class LevelPage extends StatefulWidget {
  const LevelPage({super.key});

  @override
  State<LevelPage> createState() => _LevelPageState();
}

class _LevelPageState extends State<LevelPage> {
  StreamSubscription<AccelerometerEvent>? _sub;

  // Low-pass filtered accelerometer components (gravity vector).
  double _gx = 0, _gy = 0, _gz = 9.8;

  // Tilt angles in degrees.
  double _angleX = 0, _angleY = 0;

  // Recorded snapshots, newest first. Each entry is [x, y].
  final List<List<double>> _records = [];

  static const double _alpha = 0.30; // smoothing factor (lower = smoother)
  static const double _levelThreshold = 1.0; // degrees considered "level"

  @override
  void initState() {
    super.initState();
    _sub = accelerometerEventStream().listen((e) {
      // Exponential moving average to damp noise.
      _gx = _gx + _alpha * (e.x - _gx);
      _gy = _gy + _alpha * (e.y - _gy);
      _gz = _gz + _alpha * (e.z - _gz);

      // Tilt of each axis away from horizontal.
      final ax =
          math.atan2(_gx, math.sqrt(_gy * _gy + _gz * _gz)) * 180 / math.pi;
      final ay =
          math.atan2(_gy, math.sqrt(_gx * _gx + _gz * _gz)) * 180 / math.pi;

      setState(() {
        _angleX = ax;
        _angleY = ay;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  bool get _isLevel =>
      _angleX.abs() < _levelThreshold && _angleY.abs() < _levelThreshold;

  void _record() => setState(() {
        _records.insert(0, [_angleX, _angleY]);
      });

  void _clearRecords() => setState(() => _records.clear());

  @override
  Widget build(BuildContext context) {
    final levelColor =
        _isLevel ? const Color(0xFF35D07F) : const Color(0xFFE0E4EA);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              'bu66le',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 8),
            // Numeric readout.
            Row(
              children: [
                Expanded(
                    child: _Readout(
                        label: 'X', value: _angleX, color: levelColor)),
                Expanded(
                    child: _Readout(
                        label: 'Y', value: _angleY, color: levelColor)),
              ],
            ),
            const SizedBox(height: 8),
            // Y axis track (left) + center 2D bubble.
            Expanded(
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  // Y axis track (forward/back tilt) on the left.
                  _AxisTrack(
                    label: 'Y',
                    angle: _angleY,
                    horizontal: false,
                    level: _angleY.abs() < _levelThreshold,
                  ),
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: _CenterBubble(
                            angleX: _angleX,
                            angleY: _angleY,
                            level: _isLevel,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // X axis track (left/right tilt) on the bottom.
            _AxisTrack(
              label: 'X',
              angle: _angleX,
              horizontal: true,
              level: _angleX.abs() < _levelThreshold,
            ),
            const SizedBox(height: 14),
            // Record button + recorded-values box.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  FilledButton.icon(
                    onPressed: _record,
                    icon: const Icon(Icons.fiber_manual_record, size: 14),
                    label: const Text('Record'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF35D07F),
                      foregroundColor: const Color(0xFF0E1116),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                  if (_records.isNotEmpty)
                    IconButton(
                      onPressed: _clearRecords,
                      tooltip: 'Clear',
                      icon: Icon(Icons.delete_outline,
                          color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 120,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: _records.isEmpty
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: Text('No recordings',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.4))),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: _records.length,
                              itemBuilder: (context, i) {
                                final r = _records[i];
                                // Newest first; number so 1 is the latest.
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 28,
                                        child: Text('${_records.length - i}',
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.35),
                                                fontSize: 13)),
                                      ),
                                      Expanded(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'X ${r[0].toStringAsFixed(1)}°    Y ${r[1].toStringAsFixed(1)}°',
                                            style: const TextStyle(
                                              color: Color(0xFF35D07F),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout(
      {required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14, color: Colors.white.withValues(alpha: 0.5))),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${value.toStringAsFixed(1)}°',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

/// 2D bubble that drifts toward the raised corner, like a real circular level.
class _CenterBubble extends StatelessWidget {
  const _CenterBubble(
      {required this.angleX, required this.angleY, required this.level});

  final double angleX;
  final double angleY;
  final bool level;

  static const double _maxAngle = 30; // degrees mapped to the edge

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;
        final bubbleR = size * 0.11;

        final nx = (angleX / _maxAngle).clamp(-1.0, 1.0);
        final ny = (angleY / _maxAngle).clamp(-1.0, 1.0);

        final color =
            level ? const Color(0xFF35D07F) : const Color(0xFF4DA3FF);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Vial body.
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15), width: 2),
              ),
            ),
            // Center target ring.
            Container(
              width: bubbleR * 2.4,
              height: bubbleR * 2.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25), width: 1.5),
              ),
            ),
            // Crosshair lines.
            Container(
                width: size,
                height: 1,
                color: Colors.white.withValues(alpha: 0.08)),
            Container(
                width: 1,
                height: size,
                color: Colors.white.withValues(alpha: 0.08)),
            // The bubble.
            AnimatedAlign(
              duration: const Duration(milliseconds: 90),
              alignment: Alignment(nx, ny),
              child: Container(
                width: bubbleR * 2,
                height: bubbleR * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.85),
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 16,
                        spreadRadius: 1),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A single-axis bubble level track (horizontal or vertical).
class _AxisTrack extends StatelessWidget {
  const _AxisTrack(
      {required this.label,
      required this.angle,
      required this.horizontal,
      required this.level});

  final String label;
  final double angle;
  final bool horizontal;
  final bool level;

  static const double _maxAngle = 30;

  @override
  Widget build(BuildContext context) {
    final color = level ? const Color(0xFF35D07F) : const Color(0xFF4DA3FF);
    final n = (angle / _maxAngle).clamp(-1.0, 1.0);

    final track = Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(30),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center marker.
          horizontal
              ? Container(
                  width: 2,
                  height: 24,
                  color: Colors.white.withValues(alpha: 0.2))
              : Container(
                  width: 24,
                  height: 2,
                  color: Colors.white.withValues(alpha: 0.2)),
          AnimatedAlign(
            duration: const Duration(milliseconds: 90),
            alignment: horizontal ? Alignment(n, 0) : Alignment(0, n),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.85),
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.5), blurRadius: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final labelWidget = Text(label,
        style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.bold));

    if (horizontal) {
      // Bottom row: label + horizontal track.
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            SizedBox(width: 24, child: labelWidget),
            Expanded(child: SizedBox(height: 40, child: track)),
          ],
        ),
      );
    }

    // Left column: label on top + vertical track filling the height.
    return SizedBox(
      width: 40,
      child: Column(
        children: [
          labelWidget,
          const SizedBox(height: 8),
          Expanded(child: SizedBox(width: 40, child: track)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
