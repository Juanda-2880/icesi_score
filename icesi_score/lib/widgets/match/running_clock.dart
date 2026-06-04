import 'dart:async';

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Purely presentational widget: shows a running MM:SS clock anchored to
/// [startTime]. Manages its own Timer; no BLoC access, no business logic.
/// Justified StatefulWidget exception per architecture rules.
class RunningClock extends StatefulWidget {
  final DateTime startTime;
  final TextStyle? style;
  final String? prefix;

  const RunningClock({
    super.key,
    required this.startTime,
    this.style,
    this.prefix,
  });

  @override
  State<RunningClock> createState() => _RunningClockState();
}

class _RunningClockState extends State<RunningClock> {
  late Duration _elapsed;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _elapsed = DateTime.now().difference(widget.startTime);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = DateTime.now().difference(widget.startTime);
      });
    });
  }

  @override
  void didUpdateWidget(RunningClock old) {
    super.didUpdateWidget(old);
    // Restart when a new period begins (startTime changes).
    if (old.startTime != widget.startTime) {
      _timer?.cancel();
      _elapsed = DateTime.now().difference(widget.startTime);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _elapsed = DateTime.now().difference(widget.startTime);
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = _elapsed.inMinutes;
    final s = _elapsed.inSeconds % 60;
    final clock = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    final label = widget.prefix != null ? '${widget.prefix} · $clock' : clock;
    return Text(
      label,
      style: widget.style ??
          const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
    );
  }
}
