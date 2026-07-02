class PaymentMode {
  int? id;
  late String serverId;
  late String name;
  late int tempId;

  PaymentMode();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'server_id': serverId,
      'name': name,
      'temp_id': tempId,
    };
  }

  factory PaymentMode.fromMap(Map<String, dynamic> map) {
    final paymentMode = PaymentMode();
    paymentMode.id = map['id'] as int?;
    paymentMode.serverId = map['server_id'] as String;
    paymentMode.name = map['name'] as String;
    paymentMode.tempId = map['temp_id'] as int;
    return paymentMode;
  }
}
