import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:teqbae_hrms/features/sync/presentation/bloc/sync_event.dart';
import 'package:teqbae_hrms/features/sync/presentation/bloc/sync_state.dart';

/// Shows the full outbox history and lets the user trigger a manual sync.
///
/// The page is divided into three sections:
/// - [_SyncHeader] — pending count, last sync time, and last error.
/// - Scrollable event list — every attendance event with its status badge.
/// - [_SyncFooter] — the "Sync Now" button, disabled while a sync is running.
class SyncStatusPage extends StatelessWidget {
  const SyncStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Status'),
      ),
      body: BlocBuilder<SyncBloc, SyncState>(
        builder: (context, state) {
          return Column(
            children: [
              _SyncHeader(state: state),
              Expanded(
                child: state.allEvents.isEmpty
                    ? const Center(
                        child: Text(
                          'No local attendance events recorded.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.allEvents.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final event = state.allEvents[index];
                          return _EventTile(event: event);
                        },
                      ),
              ),
              _SyncFooter(state: state),
            ],
          );
        },
      ),
    );
  }
}

/// Displays the aggregate sync status at the top of the page.
///
/// Shows:
/// - Total pending count with a highlighted chip when non-zero.
/// - The time of the last completed sync.
/// - The error message from the last failed sync, in red.
class _SyncHeader extends StatelessWidget {
  const _SyncHeader({required this.state});

  final SyncState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pending Events: ${state.pendingCount}',
                key: const Key('pending_count_text'),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (state.pendingCount > 0)
                Chip(
                  key: const Key('pending_sync_chip'),
                  label: const Text('Pending Sync'),
                  backgroundColor: Colors.orange.shade100,
                  labelStyle: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.bold),
                ),
            ],
          ),
          if (state.lastSyncTime != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Last sync: ${DateFormat('HH:mm:ss').format(state.lastSyncTime!.toLocal())}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade700),
              ),
            ),
          if (state.lastError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Error: ${state.lastError}',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

/// A single row in the event list showing the event type, timestamp, status,
/// and last error (if any).
class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final AttendanceEvent event;

  @override
  Widget build(BuildContext context) {
    final isCheckIn = event.type == AttendanceEventType.checkIn;
    final timeStr =
        DateFormat('yyyy-MM-dd HH:mm').format(event.occurredAt.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCheckIn ? Icons.login : Icons.logout,
            color: isCheckIn ? Colors.teal : Colors.blueGrey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCheckIn ? 'Check-in' : 'Check-out',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  timeStr,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (event.lastError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      event.lastError!,
                      style:
                          const TextStyle(color: Colors.red, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          _StatusChip(status: event.status, attempts: event.attempts),
        ],
      ),
    );
  }
}

/// A colour-coded chip that shows the event's sync status and attempt count.
///
/// - Orange: still pending, shows how many send attempts have been made.
/// - Green: successfully synced with the server.
/// - Red: permanently rejected by the server or local rules.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.attempts});

  final AttendanceEventStatus status;

  /// Total number of times [SyncService] has attempted to send this event.
  final int attempts;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case AttendanceEventStatus.pending:
        return Chip(
          label: Text('Pending ($attempts)'),
          backgroundColor: Colors.orange.shade50,
          labelStyle:
              TextStyle(color: Colors.orange.shade800, fontSize: 11),
        );
      case AttendanceEventStatus.synced:
        return Chip(
          label: const Text('Synced'),
          backgroundColor: Colors.green.shade50,
          labelStyle:
              TextStyle(color: Colors.green.shade800, fontSize: 11),
        );
      case AttendanceEventStatus.rejected:
        return Chip(
          label: const Text('Rejected'),
          backgroundColor: Colors.red.shade50,
          labelStyle:
              TextStyle(color: Colors.red.shade800, fontSize: 11),
        );
    }
  }
}

/// The sticky footer at the bottom of [SyncStatusPage] containing the
/// "Sync Now" button.
///
/// The button is disabled and shows a progress indicator while a sync is
/// already running to prevent duplicate requests.
class _SyncFooter extends StatelessWidget {
  const _SyncFooter({required this.state});

  final SyncState state;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            key: const Key('sync_now_button'),
            onPressed: state.isSyncing
                ? null
                : () =>
                    context.read<SyncBloc>().add(const SyncRequested()),
            icon: state.isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(state.isSyncing ? 'Syncing...' : 'Sync Now'),
          ),
        ),
      ),
    );
  }
}
