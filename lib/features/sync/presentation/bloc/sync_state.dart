import 'package:equatable/equatable.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';

enum SyncStatus { initial, syncing, success, failure }

class SyncState extends Equatable {
  const SyncState({
    this.status = SyncStatus.initial,
    this.pendingCount = 0,
    this.allEvents = const [],
    this.lastSyncTime,
    this.lastError,
    this.isSyncing = false,
  });

  final SyncStatus status;
  final int pendingCount;
  final List<AttendanceEvent> allEvents;
  final DateTime? lastSyncTime;
  final String? lastError;
  final bool isSyncing;

  SyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    List<AttendanceEvent>? allEvents,
    DateTime? lastSyncTime,
    String? lastError,
    bool? isSyncing,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      allEvents: allEvents ?? this.allEvents,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastError: lastError,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        pendingCount,
        allEvents,
        lastSyncTime,
        lastError,
        isSyncing,
      ];
}
