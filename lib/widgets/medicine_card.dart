import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/medicine_model.dart';
import 'animated_card.dart';

class MedicineCard extends StatelessWidget {
  final MedicineModel medicine;
  final VoidCallback? onTap;

  const MedicineCard({
    super.key,
    required this.medicine,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHighConfidence = medicine.confidence >= 75;
    final isMediumConfidence =
        medicine.confidence >= 60 && medicine.confidence < 75;

    return AnimatedCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 16),
      gradient: _getGradient(isHighConfidence, isMediumConfidence),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with medicine name and confidence
          Row(
            children: [
              // Medicine icon with gradient
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildConfidenceBadge(
                      medicine.confidence,
                      isHighConfidence,
                      isMediumConfidence,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Dosage
          _buildInfoRow(
            Icons.medical_information_outlined,
            'Dosage',
            medicine.dosage,
          ),

          const SizedBox(height: 12),

          // Timing
          _buildInfoRow(
            Icons.access_time_rounded,
            'Timing',
            medicine.timing,
          ),

          if (medicine.notes != null && medicine.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.info_outline,
              'Notes',
              medicine.notes!,
            ),
          ],

          // Warning for low confidence
          if (!isHighConfidence && !isMediumConfidence) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please verify with pharmacist',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.9),
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceBadge(
    double confidence,
    bool isHigh,
    bool isMedium,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHigh
                ? Icons.check_circle
                : isMedium
                    ? Icons.info
                    : Icons.warning,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            '${confidence.toStringAsFixed(0)}% ${isHigh ? 'High' : isMedium ? 'Medium' : 'Low'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getGradient(bool isHigh, bool isMedium) {
    if (isHigh) {
      return AppTheme.successGradient;
    } else if (isMedium) {
      return AppTheme.warningGradient;
    } else {
      return AppTheme.dangerGradient;
    }
  }
}
