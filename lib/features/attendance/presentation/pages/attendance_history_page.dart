import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance_repository.dart';

/// Shows a full month of attendance records along with any local pending events
/// for that month.
///
/// The user can navigate between months using chevron buttons.
/// Data is loaded fresh from the repository on each month change.
class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({
    super.key,
    required this.attendanceRepository,
    required this.initialMonth,
  });

  /// Used to fetch both server records and local pending events.
  final AttendanceRepository attendanceRepository;

  /// The month to show first, in `yyyy-MM` format (e.g. `'2024-06'`).
  final String initialMonth;

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  /// The currently displayed month, stored as the first day of the month.
  late DateTime _selectedMonthDate;

  /// `true` while an attendance fetch is in flight.
  bool _isLoading = false;

  /// Synced attendance records from the server (via local cache).
  List<AttendanceRecord> _records = [];

  /// Local pending/synced events for the displayed month that have not yet been
  /// replaced by a server record.
  List<AttendanceEvent> _localEvents = [];

  @override
  void initState() {
    super.initState();
    // Parse the initial month string into a DateTime so we can increment/decrement it.
    final parts = widget.initialMonth.split('-');
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = parts.length > 1
        ? int.tryParse(parts[1]) ?? DateTime.now().month
        : DateTime.now().month;
    _selectedMonthDate = DateTime(year, month);
    _loadMonthData();
  }

  /// Returns the current month as a `yyyy-MM` string for repository calls.
  String get _monthKey => DateFormat('yyyy-MM').format(_selectedMonthDate);

  /// Fetches attendance records and local events for [_monthKey] and
  /// updates [_records] and [_localEvents].
  Future<void> _loadMonthData() async {
    setState(() => _isLoading = true);
    final res = await widget.attendanceRepository.getAttendance(_monthKey);
    final allEvents = await widget.attendanceRepository.getAllEvents();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _records = res is Success ? (res as Success).value : [];
        _localEvents = allEvents
            .where((e) => e.companyDate.startsWith(_monthKey) && e.status != AttendanceEventStatus.rejected)
            .toList();
      });
    }
  }

  /// Moves the displayed month forward (+1) or backward (–1) by [delta] months
  /// and reloads data for the new month.
  void _changeMonth(int delta) {
    setState(() {
      _selectedMonthDate = DateTime(_selectedMonthDate.year, _selectedMonthDate.month + delta);
    });
    _loadMonthData();
  }

  @override
  Widget build(BuildContext context) {
    final title = DateFormat('MMMM yyyy').format(_selectedMonthDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
      ),
      body: Column(
        children: [
          _MonthSelector(
            title: title,
            onPrevious: () => _changeMonth(-1),
            onNext: () => _changeMonth(1),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty && _localEvents.isEmpty
                    ? Center(
                        child: Text(
                          'No records for $title.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          ..._localEvents.map((e) => _LocalEventCard(event: e)),
                          ..._records.map((r) => _RecordCard(record: r)),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

/// A navigation bar that shows the current month and left/right chevron buttons
/// to move to the previous or next month.
class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.title,
    required this.onPrevious,
    required this.onNext,
  });

  /// The human-readable month label (e.g. `'June 2024'`).
  final String title;

  /// Called when the user taps the left chevron to go to the previous month.
  final VoidCallback onPrevious;

  /// Called when the user taps the right chevron to go to the next month.
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

/// A card for a local outbox event (pending or synced) that has not yet been
/// replaced by a confirmed server record.
///
/// Shows the event type (check-in/out), time, and a colour-coded status chip.
class _LocalEventCard extends StatelessWidget {
  const _LocalEventCard({required this.event});

  final AttendanceEvent event;

  @override
  Widget build(BuildContext context) {
    final isCheckIn = event.type == AttendanceEventType.checkIn;
    final timeStr = DateFormat('HH:mm').format(event.occurredAt.toLocal());

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isCheckIn ? Icons.login : Icons.logout,
          color: Colors.orange.shade800,
        ),
        title: Text('${event.companyDate} — ${isCheckIn ? 'Check-in' : 'Check-out'} at $timeStr'),
        trailing: Chip(
          label: Text(event.status == AttendanceEventStatus.pending ? 'Pending Sync' : 'Synced'),
          backgroundColor: event.status == AttendanceEventStatus.pending ? Colors.orange.shade100 : Colors.green.shade100,
          labelStyle: TextStyle(
            color: event.status == AttendanceEventStatus.pending ? Colors.orange.shade900 : Colors.green.shade900,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

/// A card showing a fully confirmed server attendance record for a single day.
///
/// Displays the check-in time, check-out time (or '--' if not yet checked out),
/// and the total hours worked.
class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final inStr = record.checkInAt != null ? DateFormat('HH:mm').format(record.checkInAt!.toLocal()) : '--';
    final outStr = record.checkOutAt != null ? DateFormat('HH:mm').format(record.checkOutAt!.toLocal()) : '--';

    String durationStr = '--';
    if (record.checkInAt != null && record.checkOutAt != null) {
      final diff = record.checkOutAt!.difference(record.checkInAt!);
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      durationStr = '${hours}h ${minutes}m';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record.companyDate,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('In: $inStr', style: const TextStyle(color: Colors.teal)),
                Text('Out: $outStr', style: const TextStyle(color: Colors.blueGrey)),
                Text('Total: $durationStr', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
