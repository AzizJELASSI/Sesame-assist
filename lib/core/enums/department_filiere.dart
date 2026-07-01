import 'package:flutter/material.dart';



/// All units and departments that can receive and resolve tickets.
enum Department {
  // ── Unités ──────────────────────────────────────────────────────────────────
  uniteIT('uniteIT', 'Unité IT', Icons.computer_rounded),
  uniteFinance('uniteFinance', 'Unité Finance', Icons.account_balance_rounded),
  uniteStage('uniteStage', 'Unité Stage', Icons.work_outline_rounded),
  uniteScolarite('uniteScolarite', 'Unité Scolarité', Icons.school_rounded),
  uniteMarketing('uniteMarketing', 'Unité Marketing', Icons.campaign_rounded),
  uniteRH('uniteRH', 'Unité RH', Icons.people_alt_rounded),
  uniteCertification('uniteCertification', 'Unité Certification', Icons.verified_rounded),
  // ── Départements ────────────────────────────────────────────────────────────
  deptBusiness('deptBusiness', 'Département Business', Icons.business_center_rounded),
  deptINGPREPA('deptINGPREPA', 'Département ING-PREPA', Icons.engineering_rounded),
  deptTA('deptTA', 'Département TA', Icons.auto_stories_rounded),
  deptLIM('deptLIM', 'Département LIM', Icons.language_rounded);

  final String code;
  final String label;
  final IconData icon;

  const Department(this.code, this.label, this.icon);

  static Department? fromString(String? val) {
    if (val == null) return null;
    return Department.values
        .where((e) => e.name.toLowerCase() == val.toLowerCase())
        .firstOrNull;
  }
}
