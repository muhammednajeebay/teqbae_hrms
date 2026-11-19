import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/core/time/clock.dart';
import 'package:teqbae_hrms/core/time/company_calendar.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';
import 'package:teqbae_hrms/features/leave/domain/leave_repository.dart';
import 'package:teqbae_hrms/features/leave/presentation/cubit/leave_form_state.dart';

/// Manages the state of the leave application form.
///
/// [LeaveFormCubit] handles:
/// - Tracking form field values and per-field validation errors.
/// - Running [LeaveValidator] when the user submits the form.
/// - Blocking submission and showing a message when the device is offline.
/// - Mapping server 422 errors (and other server failures) to [generalError]
///   so the user understands what the server rejected.
class LeaveFormCubit extends Cubit<LeaveFormState> {
  /// Creates a [LeaveFormCubit] with all required dependencies injected.
  ///
  /// [initialState] is used in tests to start the form in a specific state.
  LeaveFormCubit({
    required LeaveRepository leaveRepository,
    required LeaveValidator validator,
    required ConnectivityService connectivityService,
    required Clock clock,
    required CompanyCalendar calendar,
    LeaveFormState initialState = const LeaveFormState(),
  })  : _leaveRepository = leaveRepository,
        _validator = validator,
        _connectivityService = connectivityService,
        _clock = clock,
        _calendar = calendar,
        super(initialState);

  final LeaveRepository _leaveRepository;
  final LeaveValidator _validator;
  final ConnectivityService _connectivityService;
  final Clock _clock;
  final CompanyCalendar _calendar;

  // ── Field change handlers ─────────────────────────────────────────────────

  /// Updates the selected leave [type] (casual / sick) in the form state.
  void typeChanged(LeaveType type) {
    emit(state.copyWith(type: type));
  }

  /// Updates the start [date] and clears any existing start-date error.
  ///
  /// Clearing the error gives immediate visual feedback that the user's new
  /// selection is being reconsidered.
  void startDateChanged(DateTime date) {
    emit(state.copyWith(
      startDate: date,
      startDateError: null,
      generalError: null,
    ));
  }

  /// Updates the end [date] and clears any existing end-date error.
  void endDateChanged(DateTime date) {
    emit(state.copyWith(
      endDate: date,
      endDateError: null,
      generalError: null,
    ));
  }

  /// Updates the [reason] text and clears any existing reason error.
  void reasonChanged(String reason) {
    emit(state.copyWith(
      reason: reason,
      reasonError: null,
      generalError: null,
    ));
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  /// Validates the form and submits the leave request if all checks pass.
  ///
  /// Submission flow:
  /// 1. Check connectivity — block immediately with an error if offline.
  /// 2. Check that both dates are selected.
  /// 3. Run [LeaveValidator] with the current balance and existing requests.
  ///    Map [ValidationFailure] to the appropriate per-field error.
  /// 4. Emit [LeaveFormStatus.submitting] and clear errors.
  /// 5. Call [LeaveRepository.applyLeave] and emit success or failure.
  ///
  /// [availableDays] and [existingRequests] are passed in from the UI because
  /// they come from the parent [LeaveListBloc] state — the cubit does not hold
  /// its own copy of that data.
  Future<void> submit({
    required int availableDays,
    required List<LeaveRequest> existingRequests,
  }) async {
    // Step 1: Connectivity guard.
    final isOnline = await _connectivityService.isOnline;
    if (!isOnline) {
      emit(state.copyWith(
        generalError: 'Internet connection is required to submit leave requests.',
        isOffline: true,
      ));
      return;
    }

    // Step 2: Date presence check.
    if (state.startDate == null) {
      emit(state.copyWith(startDateError: 'Please select a start date.'));
      return;
    }
    if (state.endDate == null) {
      emit(state.copyWith(endDateError: 'Please select an end date.'));
      return;
    }

    // Step 3: Run the full domain-level validation.
    final todayCompanyDate = _calendar.toCompanyDateTime(_clock.now());

    final validation = _validator.validate(
      today: todayCompanyDate,
      startDate: state.startDate!,
      endDate: state.endDate!,
      reason: state.reason,
      availableDays: availableDays,
      existingRequests: existingRequests,
    );

    if (validation is FailureResult<void>) {
      final failure = validation.failure;
      if (failure is ValidationFailure) {
        // Route the error to the specific field it belongs to.
        switch (failure.field) {
          case 'startDate':
            emit(state.copyWith(startDateError: failure.message));
            break;
          case 'endDate':
            emit(state.copyWith(endDateError: failure.message));
            break;
          case 'reason':
            emit(state.copyWith(reasonError: failure.message));
            break;
          default:
            emit(state.copyWith(generalError: failure.message));
            break;
        }
      } else {
        emit(state.copyWith(generalError: failure.message));
      }
      return;
    }

    // Step 4: Emit the submitting state so the UI can show a progress indicator.
    emit(state.copyWith(
      status: LeaveFormStatus.submitting,
      clearErrors: true,
    ));

    // Step 5: Send the request.
    final result = await _leaveRepository.applyLeave(
      type: state.type,
      startDate: state.startDate!,
      endDate: state.endDate!,
      reason: state.reason,
    );

    if (result is Success<LeaveRequest>) {
      // The repository automatically refreshes cached data in the background.
      emit(state.copyWith(status: LeaveFormStatus.success));
    } else if (result is FailureResult<LeaveRequest>) {
      // Server rejected the request (e.g. HTTP 422). Show the message.
      emit(state.copyWith(
        status: LeaveFormStatus.failure,
        generalError: result.failure.message,
      ));
    }
  }
}
