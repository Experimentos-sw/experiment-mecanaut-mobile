import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final normalized = text.toLowerCase();
    final bool active = normalized.contains('active') || normalized.contains('running');
    final bool paused = normalized.contains('paused') || normalized.contains('stopped');
    final bg = active
        ? const Color(0xFFE5F8EC)
        : paused
            ? const Color(0xFFF9F0D8)
            : const Color(0xFFE8EBF5);
    final fg = active
        ? const Color(0xFF14A968)
        : paused
            ? const Color(0xFFB18623)
            : const Color(0xFF5B62B3);
    final dot = active
        ? const Color(0xFF14A968)
        : paused
            ? const Color(0xFFE0B54A)
            : const Color(0xFF8E95B8);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
