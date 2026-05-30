import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class ConfidenceIndicator extends StatelessWidget {
  final double confidence;

  const ConfidenceIndicator({super.key, required this.confidence});

  Color get _color {
    if (confidence >= 80) return AppTheme.successGreen;
    if (confidence >= 60) return Colors.orange;
    return AppTheme.dangerRed;
  }

  String get _label {
    if (confidence >= 80) return 'High';
    if (confidence >= 60) return 'Medium';
    return 'Low';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(), size: 16, color: _color),
          const SizedBox(width: 4),
          Text(
            '$_label ${confidence.toStringAsFixed(0)}%',
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    if (confidence >= 80) return Icons.check_circle;
    if (confidence >= 60) return Icons.info;
    return Icons.warning;
  }
}
