import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance_repository.dart';
import 'package:teqbae_hrms/features/attendance/presentation/bloc/attendance_action_bloc.dart';
import 'package:teqbae_hrms/features/attendance/presentation/bloc/attendance_action_event.dart';
import 'package:teqbae_hrms/features/attendance/presentation/bloc/attendance_action_state.dart';
import 'package:teqbae_hrms/features/attendance/presentation/bloc/dashboard_bloc.dart';
import 'package:teqbae_hrms/features/attendance/presentation/bloc/dashboard_event.dart';
import 'package:teqbae_hrms/features/attendance/presentation/bloc/dashboard_state.dart';
import 'package:teqbae_hrms/features/attendance/presentation/pages/attendance_history_page.dart';
import 'package:teqbae_hrms/features/employee/domain/employee.dart';
import 'package:teqbae_hrms/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:teqbae_hrms/features/sync/presentation/bloc/sync_state.dart';
import 'package:teqbae_hrms/features/sync/presentation/pages/sync_status_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.attendanceRepository,
  });

  final AttendanceRepository attendanceRepository;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttendanceActionBloc, AttendanceActionState>(
      listener: (context, state) {
        if (state is AttendanceActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: state.isOffline ? Colors.orange.shade800 : Colors.green.shade800,
            ),
          );
          context.read<DashboardBloc>().add(const DashboardRefreshRequested());
        } else if (state is AttendanceActionFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade800,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('REBS HRMS'),
          actions: [
            _SyncStatusIcon(),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<DashboardBloc>().add(const DashboardRefreshRequested()),
            ),
          ],
        ),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is DashboardError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(state.message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<DashboardBloc>().add(const DashboardRefreshRequested()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            } else if (state is DashboardLoaded) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (state.isOffline || state.isFromCache)
                    _OfflineBanner(lastUpdated: state.lastUpdated, isOffline: state.isOffline),
                  _EmployeeGreetingCard(employee: state.employee),
                  const SizedBox(height: 12),
                  _TodayCard(state: state),
                  const SizedBox(height: 12),
                  _AttendanceActionButtons(state: state),
                  const SizedBox(height: 12),
                  _LeaveBalanceCard(availableDays: state.availableLeaveDays),
                  const SizedBox(height: 12),
                  _RecentAttendanceCard(
                    records: state.recentRecords,
                    attendanceRepository: attendanceRepository,
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _SyncStatusIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              key: const Key('pending_sync_badge'),
              icon: const Icon(Icons.cloud_sync),
              tooltip: 'Sync Status',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SyncStatusPage()),
                );
              },
            ),
            if (state.pendingCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${state.pendingCount}',
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.lastUpdated, required this.isOffline});

  final DateTime lastUpdated;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(lastUpdated.toLocal());
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 20, color: Colors.amber.shade900),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOffline
                  ? 'Offline. Showing cached data. Last updated $timeStr.'
                  : 'Showing cached profile. Last updated $timeStr.',
              style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeGreetingCard extends StatelessWidget {
  const _EmployeeGreetingCard({required this.employee});

  final Employee? employee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                employee?.name.isNotEmpty == true ? employee!.name[0] : 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee?.name ?? 'Employee',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${employee?.department ?? 'General'} • ${employee?.id ?? ''}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.state});

  final DashboardLoaded state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String statusText;
    Color statusColor;
    switch (state.todayStatus) {
      case TodayAttendanceStatus.notCheckedIn:
        statusText = 'Not Checked In';
        statusColor = Colors.grey;
        break;
      case TodayAttendanceStatus.checkedIn:
        statusText = 'Checked In';
        statusColor = Colors.teal;
        break;
      case TodayAttendanceStatus.checkedOut:
        statusText = 'Checked Out';
        statusColor = Colors.blueGrey;
        break;
    }

    final inStr = state.checkInTime != null ? DateFormat('HH:mm').format(state.checkInTime!.toLocal()) : '--';
    final outStr = state.checkOutTime != null ? DateFormat('HH:mm').format(state.checkOutTime!.toLocal()) : '--';

    String elapsedStr = '--';
    if (state.elapsedDuration != null) {
      final hours = state.elapsedDuration!.inHours;
      final minutes = state.elapsedDuration!.inMinutes.remainder(60);
      elapsedStr = '${hours}h ${minutes}m';
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Attendance",
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(statusText),
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatColumn(label: 'Check-in', value: inStr),
                _StatColumn(label: 'Check-out', value: outStr),
                _StatColumn(label: 'Working Time', value: elapsedStr),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _AttendanceActionButtons extends StatelessWidget {
  const _AttendanceActionButtons({required this.state});

  final DashboardLoaded state;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceActionBloc, AttendanceActionState>(
      builder: (context, actionState) {
        final isInProgress = actionState is AttendanceActionInProgress;
        final canCheckIn = state.todayStatus == TodayAttendanceStatus.notCheckedIn && !isInProgress;
        final canCheckOut = state.todayStatus == TodayAttendanceStatus.checkedIn && !isInProgress;

        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  key: const Key('check_in_button'),
                  onPressed: canCheckIn
                      ? () => context.read<AttendanceActionBloc>().add(const CheckInRequested())
                      : null,
                  icon: isInProgress && actionState.type == AttendanceEventType.checkIn
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.login),
                  label: const Text('Check In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  key: const Key('check_out_button'),
                  onPressed: canCheckOut
                      ? () => context.read<AttendanceActionBloc>().add(const CheckOutRequested())
                      : null,
                  icon: isInProgress && actionState.type == AttendanceEventType.checkOut
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.logout),
                  label: const Text('Check Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LeaveBalanceCard extends StatelessWidget {
  const _LeaveBalanceCard({required this.availableDays});

  final int availableDays;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: const Icon(Icons.calendar_month, color: Colors.deepPurple),
        title: const Text('Leave Balance', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$availableDays available days remaining'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _RecentAttendanceCard extends StatelessWidget {
  const _RecentAttendanceCard({
    required this.records,
    required this.attendanceRepository,
  });

  final List<AttendanceRecord> records;
  final AttendanceRepository attendanceRepository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Attendance',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AttendanceHistoryPage(
                          attendanceRepository: attendanceRepository,
                          initialMonth: currentMonth,
                        ),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            if (records.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('No attendance records found.', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...records.map(
                (r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.companyDate, style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        '${r.checkInAt != null ? DateFormat('HH:mm').format(r.checkInAt!.toLocal()) : '--'} - ${r.checkOutAt != null ? DateFormat('HH:mm').format(r.checkOutAt!.toLocal()) : '--'}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
