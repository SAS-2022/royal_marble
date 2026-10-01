import 'package:cloud_firestore/cloud_firestore.dart';

enum PayType { monthly, daily, hourly }

extension PayTypeLabel on PayType {
  String get label => switch (this) {
        PayType.monthly => 'Monthly salary',
        PayType.daily => 'Daily rate',
        PayType.hourly => 'Hourly rate',
      };

  /// What the basic amount is "per".
  String get unit => switch (this) {
        PayType.monthly => '/ month',
        PayType.daily => '/ day',
        PayType.hourly => '/ hour',
      };
}

class Allowance {
  final String name;
  final double amount;
  const Allowance(this.name, this.amount);

  Map<String, dynamic> toMap() => {'name': name, 'amount': amount};

  factory Allowance.fromMap(Map m) =>
      Allowance('${m['name'] ?? ''}', (m['amount'] as num?)?.toDouble() ?? 0);
}

/// A worker's pay package, stored at `payroll/{uid}`.
///
/// Allowances (housing, transport, food, other) are monthly amounts regardless
/// of [payType]; [basic] is per month, day or hour depending on [payType].
class SalaryPackage {
  final String currency;
  final PayType payType;
  final double basic;
  final double housing;
  final double transport;
  final double food;
  final List<Allowance> other;
  final DateTime? effectiveFrom;
  final String? notes;
  final DateTime? updatedAt;
  final String? updatedBy;

  const SalaryPackage({
    this.currency = 'AED',
    this.payType = PayType.monthly,
    this.basic = 0,
    this.housing = 0,
    this.transport = 0,
    this.food = 0,
    this.other = const [],
    this.effectiveFrom,
    this.notes,
    this.updatedAt,
    this.updatedBy,
  });

  double get monthlyAllowances =>
      housing + transport + food + other.fold(0.0, (t, a) => t + a.amount);

  /// Full monthly package; only meaningful for monthly pay.
  double? get monthlyTotal =>
      payType == PayType.monthly ? basic + monthlyAllowances : null;

  bool get isEmpty => basic == 0 && monthlyAllowances == 0;

  static double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;

  factory SalaryPackage.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const SalaryPackage();
    return SalaryPackage(
      currency: m['currency'] ?? 'AED',
      payType: PayType.values.asNameMap()[m['payType']] ?? PayType.monthly,
      basic: _d(m['basic']),
      housing: _d(m['housing']),
      transport: _d(m['transport']),
      food: _d(m['food']),
      other: [
        for (final a in (m['other'] as List?) ?? const [])
          if (a is Map) Allowance.fromMap(a)
      ],
      effectiveFrom: (m['effectiveFrom'] as Timestamp?)?.toDate(),
      notes: m['notes'] as String?,
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: m['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'currency': currency,
        'payType': payType.name,
        'basic': basic,
        'housing': housing,
        'transport': transport,
        'food': food,
        'other': [for (final a in other) a.toMap()],
        'effectiveFrom':
            effectiveFrom == null ? null : Timestamp.fromDate(effectiveFrom!),
        'notes': notes,
      };
}
