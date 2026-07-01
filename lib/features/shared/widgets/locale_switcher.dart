// ─── SEASAME Assist-Pro — Locale Switcher Widget ──────────────────────────────
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';

class LocaleSwitcher extends ConsumerWidget {
  const LocaleSwitcher({super.key});

  static const _locales = [
    (Locale('en'), 'EN', '🇬🇧'),
    (Locale('fr'), 'FR', '🇫🇷'),
    (Locale('ar'), 'AR', '🇩🇿'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<Locale>(
      tooltip: 'Change language',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 40),
      itemBuilder: (context) => _locales.map((l) {
        final isSelected = l.$1.languageCode == current.languageCode;
        return PopupMenuItem<Locale>(
          value: l.$1,
          child: Row(
            children: [
              Text(l.$3, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Text(
                l.$2,
                style: TextStyle(
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? scheme.primary : null,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Icon(Icons.check_rounded, color: scheme.primary, size: 16),
              ],
            ],
          ),
        );
      }).toList(),
      onSelected: (locale) {
        ref.read(localeProvider.notifier).setLocale(locale);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _locales
                  .firstWhere(
                    (l) => l.$1.languageCode == current.languageCode,
                    orElse: () => _locales.first,
                  )
                  .$3,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              current.languageCode.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
