class SyncQueue {
  int? id;
  late String entityType;
  late int entityId;
  late String status;
  late DateTime createdDate;

  SyncQueue();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'status': status,
      'created_date': createdDate.toIso8601String(),
    };
  }

  factory SyncQueue.fromMap(Map<String, dynamic> map) {
    final entry = SyncQueue();
    entry.id = map['id'] as int?;
    entry.entityType = map['entity_type'] as String;
    entry.entityId = map['entity_id'] as int;
    entry.status = map['status'] as String;
    entry.createdDate = DateTime.parse(map['created_date'] as String);
    return entry;
  }
}
