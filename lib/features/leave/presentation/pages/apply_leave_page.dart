import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';
import 'package:teqbae_hrms/features/leave/presentation/cubit/leave_form_cubit.dart';
import 'package:teqbae_hrms/features/leave/presentation/cubit/leave_form_state.dart';

/// The form screen where an employee fills in and submits a leave request.
///
/// Requires a [LeaveFormCubit] to be provided above it in the widget tree
/// (created by [LeaveListPage] before pushing this route).
///
/// On success: pops back to the list page with a `true` return value so the
/// list can trigger a refresh.
/// On failure: shows the server error in a red SnackBar and keeps the form
/// open so the user can correct the issue.
class ApplyLeavePage extends StatelessWidget {
  const ApplyLeavePage({
    super.key,
    required this.availableDays,
    required this.existingRequests,
  });

  /// Current available leave days — passed to [LeaveFormCubit.submit] for the
  /// balance validation rule.
  final int availableDays;

  /// Already submitted requests — used by [LeaveFormCubit] to check for date
  /// overlaps before submitting.
  final List<LeaveRequest> existingRequests;

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeaveFormCubit, LeaveFormState>(
      listener: (context, state) {
        if (state.status == LeaveFormStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Leave application submitted successfully.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state.generalError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.generalError!),
              backgroundColor: Colors.red.shade800,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Apply for Leave'),
        ),
        body: BlocBuilder<LeaveFormCubit, LeaveFormState>(
          builder: (context, state) {
            final cubit = context.read<LeaveFormCubit>();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (state.isOffline)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi_off, color: Colors.amber.shade900),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You need an internet connection to apply for leave.',
                            style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                _TypeSelector(
                  selectedType: state.type,
                  onTypeChanged: cubit.typeChanged,
                ),
                const SizedBox(height: 16),
                _DatePickerField(
                  label: 'Start Date',
                  selectedDate: state.startDate,
                  errorText: state.startDateError,
                  onDateSelected: cubit.startDateChanged,
                ),
                const SizedBox(height: 16),
                _DatePickerField(
                  label: 'End Date',
                  selectedDate: state.endDate,
                  errorText: state.endDateError,
                  onDateSelected: cubit.endDateChanged,
                ),
                if (state.daysRequested > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Requested Duration: ${state.daysRequested} day(s)',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ),
                const SizedBox(height: 16),
                _ReasonTextField(
                  initialValue: state.reason,
                  errorText: state.reasonError,
                  onChanged: cubit.reasonChanged,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    key: const Key('submit_leave_button'),
                    onPressed: state.status == LeaveFormStatus.submitting
                        ? null
                        : () => cubit.submit(
                              availableDays: availableDays,
                              existingRequests: existingRequests,
                            ),
                    child: state.status == LeaveFormStatus.submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit Application'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A segmented button that lets the user choose between Casual and Sick leave.
class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.selectedType,
    required this.onTypeChanged,
  });

  /// The currently selected leave type (drives the highlighted segment).
  final LeaveType selectedType;

  /// Called whenever the user switches segments.
  final ValueChanged<LeaveType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<LeaveType>(
      segments: const [
        ButtonSegment(value: LeaveType.casual, label: Text('Casual Leave')),
        ButtonSegment(value: LeaveType.sick, label: Text('Sick Leave')),
      ],
      selected: {selectedType},
      onSelectionChanged: (set) => onTypeChanged(set.first),
    );
  }
}

/// A tappable date selector field that opens Flutter's [showDatePicker].
///
/// Displays the selected date in `yyyy-MM-dd` format, or "Select Date" as a
/// placeholder. Shows an error message below the field when [errorText] is set.
class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.selectedDate,
    required this.errorText,
    required this.onDateSelected,
  });

  /// Label shown above the field (e.g. "Start Date").
  final String label;

  /// The currently selected date, or `null` if none has been chosen yet.
  final DateTime? selectedDate;

  /// Validation error to display below the field, or `null` if the field is valid.
  final String? errorText;

  /// Called with the [DateTime] the user picks in the date-picker dialog.
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final dateStr = selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : 'Select Date';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? now,
              firstDate: DateTime(now.year - 1),
              lastDate: DateTime(now.year + 2),
            );
            if (picked != null) onDateSelected(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: errorText != null ? Colors.red : Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateStr, style: TextStyle(color: selectedDate != null ? Colors.black : Colors.grey)),
                const Icon(Icons.calendar_today, size: 18),
              ],
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }
}

/// A multi-line text field for the leave reason.
///
/// Displays an error message inline (via [TextField.decoration.errorText])
/// when [errorText] is non-null.
class _ReasonTextField extends StatelessWidget {
  const _ReasonTextField({
    required this.initialValue,
    required this.errorText,
    required this.onChanged,
  });

  /// The initial text to populate the field with.
  final String initialValue;

  /// Validation error shown below the field, or `null` if the field is valid.
  final String? errorText;

  /// Called on every keystroke with the new text value.
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reason (minimum 10 characters)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          onChanged: onChanged,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Provide details for your leave request...',
            border: const OutlineInputBorder(),
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
