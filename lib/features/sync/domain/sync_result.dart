import 'package:equatable/equatable.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';

class SyncResult extends Equatable {
  const SyncResult({
    required this.syncedCount,
    required this.rejectedCount,
    required this.pendingCount,
    this.failure,
  });

  final int syncedCount;
  final int rejectedCount;
  final int pendingCount;
  final Failure? failure;

  bool get isSuccess => failure == null && rejectedCount == 0;

  @override
  List<Object?> get props => [syncedCount, rejectedCount, pendingCount, failure];
}
