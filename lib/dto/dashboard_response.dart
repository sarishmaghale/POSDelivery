class DashboardResponse {
  final String driverName;
  final List<String> assignedCategoryIds;
  final List<String> assignedProductIds;
  final int todaysDeliveries;
  final int estimatedBillsCreated;
  final int pendingSync;
  final String? lastSyncTime;

  DashboardResponse({
    required this.driverName,
    required this.assignedCategoryIds,
    required this.assignedProductIds,
    required this.todaysDeliveries,
    required this.estimatedBillsCreated,
    required this.pendingSync,
    this.lastSyncTime,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      driverName: json['driverName'] as String,
      assignedCategoryIds:
          (json['assignedCategoryIds'] as List).cast<String>(),
      assignedProductIds:
          (json['assignedProductIds'] as List).cast<String>(),
      todaysDeliveries: json['todaysDeliveries'] as int,
      estimatedBillsCreated: json['estimatedBillsCreated'] as int,
      pendingSync: json['pendingSync'] as int,
      lastSyncTime: json['lastSyncTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverName': driverName,
      'assignedCategoryIds': assignedCategoryIds,
      'assignedProductIds': assignedProductIds,
      'todaysDeliveries': todaysDeliveries,
      'estimatedBillsCreated': estimatedBillsCreated,
      'pendingSync': pendingSync,
      'lastSyncTime': lastSyncTime,
    };
  }
}
