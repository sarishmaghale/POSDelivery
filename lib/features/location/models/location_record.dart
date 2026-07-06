class LocationRecord {
  final int? id;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy;
  final double? speed;
  final bool synced;
  final String? driverId;

  LocationRecord({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
    this.speed,
    this.synced = false,
    this.driverId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
        'accuracy': accuracy,
        'speed': speed,
        'synced': synced ? 1 : 0,
        'driverId': driverId,
      };

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
        'accuracy': accuracy,
        'speed': speed,
        'driverId': driverId,
      };

  factory LocationRecord.fromMap(Map<String, dynamic> map) => LocationRecord(
        id: map['id'] as int?,
        latitude: map['latitude'] as double,
        longitude: map['longitude'] as double,
        timestamp: DateTime.parse(map['timestamp'] as String),
        accuracy: map['accuracy'] as double?,
        speed: map['speed'] as double?,
        synced: (map['synced'] as int?) == 1,
        driverId: map['driverId'] as String?,
      );

  factory LocationRecord.fromJson(Map<String, dynamic> json) => LocationRecord(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        speed: (json['speed'] as num?)?.toDouble(),
        driverId: json['driverId'] as String,
      );

  LocationRecord copyWithSynced(bool synced) => LocationRecord(
        id: id,
        latitude: latitude,
        longitude: longitude,
        timestamp: timestamp,
        accuracy: accuracy,
        speed: speed,
        synced: synced,
        driverId: driverId,
      );
}