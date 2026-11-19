import 'package:equatable/equatable.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/sync/domain/sync_result.dart';

sealed class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class SyncStarted extends SyncEvent {
  const SyncStarted();
}

class SyncRequested extends SyncEvent {
  const SyncRequested({this.currentMonth});

  final String? currentMonth;

  @override
  List<Object?> get props => [currentMonth];
}

class SyncEventsUpdated extends SyncEvent {
  const SyncEventsUpdated(this.allEvents);

  final List<AttendanceEvent> allEvents;

  @override
  List<Object?> get props => [allEvents];
}

class SyncResultReceived extends SyncEvent {
  const SyncResultReceived(this.result);

  final SyncResult result;

  @override
  List<Object?> get props => [result];
}
