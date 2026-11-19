import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/core/time/clock.dart';
import 'package:teqbae_hrms/core/time/company_calendar.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';
import 'package:teqbae_hrms/features/leave/domain/leave_repository.dart';
import 'package:teqbae_hrms/features/leave/presentation/bloc/leave_list_bloc.dart';
import 'package:teqbae_hrms/features/leave/presentation/bloc/leave_list_event.dart';
import 'package:teqbae_hrms/features/leave/presentation/bloc/leave_list_state.dart';
import 'package:teqbae_hrms/features/leave/presentation/cubit/leave_form_cubit.dart';
import 'package:teqbae_hrms/features/leave/presentation/pages/apply_leave_page.dart';

class LeaveListPage extends StatelessWidget {
  const LeaveListPage({
    super.key,
    required this.leaveRepository,
    required this.connectivityService,
    required this.clock,
    required this.calendar,
  });

  final LeaveRepository leaveRepository;
  final ConnectivityService connectivityService;
  final Clock clock;
  final CompanyCalendar calendar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<LeaveListBloc>().add(const LeaveListRefreshRequested()),
          ),
        ],
      ),
      body: BlocBuilder<LeaveListBloc, LeaveListState>(
        builder: (context, state) {
          if (state.status == LeaveListStatus.loading && state.requests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<LeaveListBloc>().add(const LeaveListRefreshRequested());
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (state.isOffline)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi_off, color: Colors.amber.shade900, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Offline. Showing cached leave records.',
                            style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                _BalanceCard(availableDays: state.balance?.availableDays ?? 0),
                const SizedBox(height: 16),
                const Text(
                  'Requests History',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (state.requests.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No leave requests found.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...state.requests.map((req) => _LeaveRequestCard(request: req)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: BlocBuilder<LeaveListBloc, LeaveListState>(
        builder: (context, state) {
          return FloatingActionButton.extended(
            key: const Key('apply_leave_fab'),
            icon: const Icon(Icons.add),
            label: const Text('Apply Leave'),
            onPressed: () async {
              final submitted = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => LeaveFormCubit(
                      leaveRepository: leaveRepository,
                      validator: const LeaveValidator(),
                      connectivityService: connectivityService,
                      clock: clock,
                      calendar: calendar,
                    ),
                    child: ApplyLeavePage(
                      availableDays: state.balance?.availableDays ?? 0,
                      existingRequests: state.requests,
                    ),
                  ),
                ),
              );

              if (submitted == true && context.mounted) {
                context.read<LeaveListBloc>().add(const LeaveListRefreshRequested());
              }
            },
          );
        },
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.availableDays});

  final int availableDays;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_available, color: Colors.deepPurple, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Available Leave Balance', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text(
                    '$availableDays days',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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

class _LeaveRequestCard extends StatelessWidget {
  const _LeaveRequestCard({required this.request});

  final LeaveRequest request;

  @override
  Widget build(BuildContext context) {
    final startStr = DateFormat('yyyy-MM-dd').format(request.startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(request.endDate);
    final duration = request.endDate.difference(request.startDate).inDays + 1;
    final typeStr = request.type == LeaveType.casual ? 'Casual Leave' : 'Sick Leave';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(typeStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                _LeaveStatusChip(status: request.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$startStr to $endStr ($duration day${duration > 1 ? 's' : ''})',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              request.reason,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveStatusChip extends StatelessWidget {
  const _LeaveStatusChip({required this.status});

  final LeaveStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case LeaveStatus.pending:
        return Chip(
          label: const Text('Pending'),
          backgroundColor: Colors.orange.shade50,
          labelStyle: TextStyle(color: Colors.orange.shade800, fontSize: 11, fontWeight: FontWeight.bold),
        );
      case LeaveStatus.approved:
        return Chip(
          label: const Text('Approved'),
          backgroundColor: Colors.green.shade50,
          labelStyle: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.bold),
        );
      case LeaveStatus.rejected:
        return Chip(
          label: const Text('Rejected'),
          backgroundColor: Colors.red.shade50,
          labelStyle: TextStyle(color: Colors.red.shade800, fontSize: 11, fontWeight: FontWeight.bold),
        );
    }
  }
}
