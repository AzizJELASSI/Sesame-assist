// ─── SEASAME Assist-Pro — SLA Policy Model ────────────────────────────────────
class SlaPolicy {
  final String id;
  final String priority; // 'low' | 'medium' | 'high'
  final int responseTimeH;    // business hours
  final int resolutionTimeH;  // business hours
  final DateTime createdAt;
  final DateTime updatedAt;

  const SlaPolicy({
    required this.id,
    required this.priority,
    required this.responseTimeH,
    required this.resolutionTimeH,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SlaPolicy.fromJson(Map<String, dynamic> json) => SlaPolicy(
        id: json['id'] as String,
        priority: json['priority'] as String,
        responseTimeH: json['response_time_h'] as int,
        resolutionTimeH: json['resolution_time_h'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'priority': priority,
        'response_time_h': responseTimeH,
        'resolution_time_h': resolutionTimeH,
      };

  SlaPolicy copyWith({
    int? responseTimeH,
    int? resolutionTimeH,
  }) =>
      SlaPolicy(
        id: id,
        priority: priority,
        responseTimeH: responseTimeH ?? this.responseTimeH,
        resolutionTimeH: resolutionTimeH ?? this.resolutionTimeH,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
