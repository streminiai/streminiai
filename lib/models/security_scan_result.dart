class SecurityScanResult {
  final bool isSafe;
  final String threatLevel;
  final List<String>? warnings;

  SecurityScanResult({
    required this.isSafe,
    required this.threatLevel,
    this.warnings,
  });

  factory SecurityScanResult.fromJson(Map<String, dynamic> json) {
    return SecurityScanResult(
      isSafe: json['isSafe'] as bool? ?? true,
      threatLevel: json['threatLevel'] as String? ?? 'safe',
      warnings: (json['warnings'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  bool get isHighThreat => threatLevel == 'high';
  bool get isMediumThreat => threatLevel == 'medium';
}
