import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
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
import 'package:teqbae_hrms/core/config/app_config.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/core/network/rebs_api.dart';
import 'package:teqbae_hrms/core/time/clock.dart';
import 'package:teqbae_hrms/core/time/company_calendar.dart';
import 'package:teqbae_hrms/features/attendance/data/location_service.dart';
import 'package:teqbae_hrms/features/debug/presentation/debug_page.dart';
import 'package:teqbae_hrms/features/leave/domain/leave_repository.dart';
import 'package:teqbae_hrms/features/leave/presentation/pages/leave_list_page.dart';
import 'package:teqbae_hrms/features/sync/presentation/bloc/sync_state.dart';
import 'package:teqbae_hrms/features/sync/presentation/pages/sync_status_page.dart';

/// The main dashboard screen of the application.
///
/// This screen displays:
/// - The employee's name, ID, and department.
/// - Today's check-in/out status, recorded times, and active work duration.
/// - Big check-in and check-out action buttons with geofencing.
/// - Current available leave balance with a shortcut to the leave requests page.
/// - The 5 most recent attendance records with a link to full monthly history.
/// - App bar shortcuts for sync status, manual refresh, and developer debug panel.
class DashboardPage extends StatelessWidget {
  /// Creates the dashboard page with required dependencies.
  const DashboardPage({
    super.key,
    required this.attendanceRepository,
    this.leaveRepository,
    this.connectivityService,
    this.clock,
    this.calendar,
    this.config,
    this.api,
    this.locationService,
  });

  /// Repository for reading attendance records and local outbox events.
  final AttendanceRepository attendanceRepository;

  /// Optional repository for leave balance and requests (used to navigate to leave screen).
  final LeaveRepository? leaveRepository;

  /// Service to check internet connectivity status.
  final ConnectivityService? connectivityService;

  /// Clock service to obtain current time.
  final Clock? clock;

  /// Calendar service to handle company timezones.
  final CompanyCalendar? calendar;

  /// App configuration loaded at build time.
  final AppConfig? config;

  /// API client used by the debug panel to test server scenarios.
  final RebsApi? api;

  /// Location service supporting simulated presets for testing.
  final ConfigurableLocationService? locationService;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttendanceActionBloc, AttendanceActionState>(
      listener: (context, state) {
        if (state is AttendanceActionSuccess) {
          // Notify the user of successful local save or sync.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: state.isOffline ? Colors.orange.shade800 : Colors.green.shade800,
            ),
          );
          // Refresh dashboard data to update status and timers.
          context.read<DashboardBloc>().add(const DashboardRefreshRequested());
        } else if (state is AttendanceActionFailure) {
          if (state.isLocationPermanentlyDenied) {
            _showPermissionDeniedDialog(context);
          } else if (state.isLocationServiceDisabled) {
            _showLocationDisabledDialog(context);
          } else {
            // Display the reason why the action failed (e.g. outside geofence, already checked in).
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade800,
              ),
            );
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('REBS HRMS'),
          actions: [
            // Only show the debug panel button if test tools are provided.
            if (config != null && api != null && locationService != null)
              IconButton(
                key: const Key('debug_panel_button'),
                icon: const Icon(Icons.tune),
                tooltip: 'Debug & Test Panel',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DebugPage(
                        config: config!,
                        api: api!,
                        locationService: locationService!,
                      ),
                    ),
                  );
                },
              ),
            // Cloud sync button with a badge for pending outbox items.
            _SyncStatusIcon(),
            // Manual refresh button.
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
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
                  // Banner shown when the device is offline or presenting cached data.
                  if (state.isOffline || state.isFromCache)
                    _OfflineBanner(lastUpdated: state.lastUpdated, isOffline: state.isOffline),
                  // Employee profile overview card.
                  _EmployeeGreetingCard(employee: state.employee),
                  const SizedBox(height: 12),
                  // Today's attendance status and times.
                  _TodayCard(state: state),
                  const SizedBox(height: 12),
                  // Check-in and check-out action buttons.
                  _AttendanceActionButtons(state: state),
                  const SizedBox(height: 12),
                  // Leave balance card that navigates to the leave request list.
                  _LeaveBalanceCard(
                    availableDays: state.availableLeaveDays,
                    onTap: leaveRepository != null && connectivityService != null && clock != null && calendar != null
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => LeaveListPage(
                                  leaveRepository: leaveRepository!,
                                  connectivityService: connectivityService!,
                                  clock: clock!,
                                  calendar: calendar!,
                                ),
                              ),
                            );
                          }
                        : null,
                  ),
                  const SizedBox(height: 12),
                  // Recent 5 attendance records.
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

  /// Displays an alert dialog when location permission is permanently denied,
  /// giving the user a direct button to open system app settings.
  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.location_off, size: 40, color: Colors.deepOrange),
        title: const Text('Location Permission Required'),
        content: const Text(
          'REBS HRMS requires precise location access to verify that you are within 200 metres of the office for check-in and check-out.\n\nLocation permission is permanently denied. Please tap "Open Settings" to enable location permission for REBS HRMS.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.settings),
            label: const Text('Open Settings'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              locationService?.openAppSettings() ?? Geolocator.openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  /// Displays an alert dialog when device location services (GPS hardware switch) are turned off,
  /// giving the user a direct button to open device location settings.
  void _showLocationDisabledDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.gps_off, size: 40, color: Colors.amber),
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Device location services (GPS) are turned off. Please turn on location services so REBS HRMS can verify office proximity.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.location_on),
            label: const Text('Turn On Location'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              locationService?.openLocationSettings() ?? Geolocator.openLocationSettings();
            },
          ),
        ],
      ),
    );
  }
}

/// An icon button in the app bar that shows a badge when outbox events are waiting to sync.
///
/// Tapping this opens the [SyncStatusPage] to review individual pending events.
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
            // Show badge counter if any events are waiting in the offline outbox.
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

/// A notification banner displayed when the app is offline or reading from local cache.
class _OfflineBanner extends StatelessWidget {
  /// Creates the offline banner with timestamp and status.
  const _OfflineBanner({required this.lastUpdated, required this.isOffline});

  /// The timestamp when the cached data was last updated.
  final DateTime lastUpdated;

  /// Whether the device is currently completely offline.
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

/// A card displaying the employee's avatar, full name, department, and employee ID.
class _EmployeeGreetingCard extends StatelessWidget {
  /// Creates the employee greeting card.
  const _EmployeeGreetingCard({required this.employee});

  /// The employee profile details, or `null` if loading/unavailable.
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

/// A card showing today's attendance summary: status, check-in time, check-out time, and working time.
class _TodayCard extends StatelessWidget {
  /// Creates the card using the loaded dashboard state.
  const _TodayCard({required this.state});

  /// The loaded dashboard state containing today's attendance metrics.
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

/// A helper widget to render a single stat with a label and value vertically aligned.
class _StatColumn extends StatelessWidget {
  /// Creates the stat column widget.
  const _StatColumn({required this.label, required this.value});

  /// The description label (e.g. "Check-in").
  final String label;

  /// The formatted display value (e.g. "09:15").
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

/// The check-in and check-out buttons that trigger attendance actions with location verification.
class _AttendanceActionButtons extends StatelessWidget {
  /// Creates the action buttons widget.
  const _AttendanceActionButtons({required this.state});

  /// The loaded dashboard state to determine whether buttons should be enabled.
  final DashboardLoaded state;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceActionBloc, AttendanceActionState>(
      builder: (context, actionState) {
        final isInProgress = actionState is AttendanceActionInProgress;
        // Check-in allowed only if user has not yet checked in today and no action is currently running.
        final canCheckIn = state.todayStatus == TodayAttendanceStatus.notCheckedIn && !isInProgress;
        // Check-out allowed only if user is checked in and not yet checked out.
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

/// A card showing the employee's available leave days with an arrow navigating to the leave screen.
class _LeaveBalanceCard extends StatelessWidget {
  /// Creates the leave balance card.
  const _LeaveBalanceCard({required this.availableDays, this.onTap});

  /// The number of available leave days.
  final int availableDays;

  /// Callback when the user taps the card to view leave details.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: const Icon(Icons.calendar_month, color: Colors.deepPurple),
        title: const Text('Leave Balance', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$availableDays available days remaining (tap to view)'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// A card that lists the employee's last 5 attendance records with a "View All" link to monthly history.
class _RecentAttendanceCard extends StatelessWidget {
  /// Creates the recent attendance list card.
  const _RecentAttendanceCard({
    required this.records,
    required this.attendanceRepository,
  });

  /// Up to 5 most recent attendance records.
  final List<AttendanceRecord> records;

  /// Attendance repository passed to the history page when opened.
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
