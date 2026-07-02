// ─── SEASAME Assist-Pro — SLA Status Enum ─────────────────────────────────────
import 'package:flutter/material.dart';
import '../theme.dart';

enum SlaStatus {
  onTrack,  // > 25 % of time remaining
  atRisk,   // 0–25 % of time remaining
  breached, // deadline passed or sla_breached flag is true
}

extension SlaStatusExtension on SlaStatus {
  String get label => switch (this) {
        SlaStatus.onTrack  => 'On Track',
        SlaStatus.atRisk   => 'At Risk',
        SlaStatus.breached => 'Breached',
      };

  Color get color => switch (this) {
        SlaStatus.onTrack  => AppColors.primary500,
        SlaStatus.atRisk   => const Color(0xFFF59E0B), // amber
        SlaStatus.breached => const Color(0xFFEF4444), // red
      };

  IconData get icon => switch (this) {
        SlaStatus.onTrack  => Icons.check_circle_outline_rounded,
        SlaStatus.atRisk   => Icons.warning_amber_rounded,
        SlaStatus.breached => Icons.error_outline_rounded,
      };
}
