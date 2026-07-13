import 'dart:convert';

class PaymentEntry {
  String? paymentModeId;
  String? paymentModeName;
  double amount;

  PaymentEntry({
    this.paymentModeId,
    this.paymentModeName,
    this.amount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'paymentModeId': paymentModeId,
      'paymentModeName': paymentModeName,
      'amount': amount,
    };
  }

  factory PaymentEntry.fromJson(Map<String, dynamic> json) {
    return PaymentEntry(
      paymentModeId: json['paymentModeId'] as String?,
      paymentModeName: json['paymentModeName'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }

  static List<PaymentEntry> listFromJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final list = jsonDecode(jsonString) as List;
      return list.map((e) => PaymentEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<PaymentEntry> entries) {
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }
}
