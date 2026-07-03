import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'models/location_record.dart';
import 'services/location_service.dart';
import 'services/location_database_service.dart';
import 'services/location_sync_service.dart';
import 'services/location_api_service.dart';
import '../../core/network/providers.dart';

final locationServiceProvider = Provider((_) => LocationService());
final locationDatabaseServiceProvider = Provider((_) => LocationDatabaseService());
final locationSyncServiceProvider = Provider((ref) => LocationSyncService(ref.read(locationApiServiceProvider)));
final locationApiServiceProvider = Provider((ref) => LocationApiService(ref.read(dioProvider)));

final locationStateProvider = StateNotifierProvider<LocationStateNotifier, LocationState>((ref) {
  return LocationStateNotifier(
    ref.read(locationServiceProvider),
    ref.read(locationDatabaseServiceProvider),
    ref.read(locationSyncServiceProvider),
    initialDriverId: '0271B366-CDA5-48C2-9308-29AD5153081F',
  );
});

class LocationState {
  final Position? currentPosition;
  final List<LocationRecord> recentLocations;
  final bool isTracking;
  final int pendingSyncCount;
  final bool isOnline;
  final String? error;
  final String? driverId;

  const LocationState({
    this.currentPosition,
    this.recentLocations = const [],
    this.isTracking = false,
    this.pendingSyncCount = 0,
    this.isOnline = false,
    this.error,
    this.driverId,
  });

  LocationState copyWith({
    Position? currentPosition,
    List<LocationRecord>? recentLocations,
    bool? isTracking,
    int? pendingSyncCount,
    bool? isOnline,
    String? error,
    String? driverId,
  }) =>
      LocationState(
        currentPosition: currentPosition ?? this.currentPosition,
        recentLocations: recentLocations ?? this.recentLocations,
        isTracking: isTracking ?? this.isTracking,
        pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
        isOnline: isOnline ?? this.isOnline,
        error: error,
        driverId: driverId ?? this.driverId,
      );
}

class LocationStateNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;
  final LocationDatabaseService _db;
  final String? _driverId;
  final LocationSyncService _syncService;
  Timer? _trackingTimer;
  StreamSubscription<Position>? _positionStream;

  LocationStateNotifier(
    this._locationService,
    this._db,
    this._syncService, {
    String? initialDriverId,
  }) : _driverId = initialDriverId,
       super(const LocationState()) {
    _init();
  }

  Future<void> _init() async {
    _syncService.startPeriodicSync();
    final online = await _syncService.isOnline();
    final pending = await _db.getPendingCount();
    final existingLocations = await _db.getAllLocations();

    state = state.copyWith(isOnline: online, pendingSyncCount: pending, recentLocations: existingLocations);
  }

  Future<void> startTracking() async {
    final permission = await _locationService.requestPermission();
    if (!permission) {
      state = state.copyWith(error: 'Location permission denied');
      return;
    }

    state = state.copyWith(isTracking: true, error: null);

    _positionStream = _locationService.getPositionStream().listen(
      (pos) => _handlePosition(pos),
      onError: (e) => state = state.copyWith(error: e.toString()),
    );

    _trackingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) async {
        final pos = await _locationService.getCurrentPosition();
        if (pos != null) _handlePosition(pos);
      },
    );
  }

  Future<void> _handlePosition(Position pos) async {
    state = state.copyWith(currentPosition: pos);
    final record = LocationRecord(
      latitude: pos.latitude,
      longitude: pos.longitude,
      timestamp: DateTime.now(),
      accuracy: pos.accuracy,
      speed: pos.speed,
      driverId: _driverId,
    );

    await _db.insertLocation(record);

    final recent = await _db.getAllLocations();
    final pending = await _db.getPendingCount();
    state = state.copyWith(recentLocations: recent, pendingSyncCount: pending);

    final online = await _syncService.isOnline();
    if (online) {
      state = state.copyWith(isOnline: true);
      await _syncService.sync();
      final pendingAfter = await _db.getPendingCount();
      state = state.copyWith(pendingSyncCount: pendingAfter);
    }
  }

  Future<void> stopTracking() async {
    _trackingTimer?.cancel();
    _trackingTimer = null;
    await _positionStream?.cancel();
    _positionStream = null;
    state = state.copyWith(isTracking: false);

    // Final sync
    if (await _syncService.isOnline()) {
      await _syncService.sync();
      final pending = await _db.getPendingCount();
      state = state.copyWith(pendingSyncCount: pending);
    }
  }

  Future<void> manualSync() async {
    state = state.copyWith(error: null);
    final online = await _syncService.isOnline();
    state = state.copyWith(isOnline: online);
    if (online) {
      await _syncService.sync();
      final pending = await _db.getPendingCount();
      state = state.copyWith(pendingSyncCount: pending);
    } else {
      state = state.copyWith(error: 'No internet connection');
    }
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    _positionStream?.cancel();
    _syncService.dispose();
    super.dispose();
  }
}