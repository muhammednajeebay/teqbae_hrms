import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/core/time/clock.dart';
import 'package:teqbae_hrms/core/time/company_calendar.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';
import 'package:teqbae_hrms/features/leave/domain/leave_repository.dart';
import 'package:teqbae_hrms/features/leave/presentation/cubit/leave_form_state.dart';

class LeaveFormCubit extends Cubit<LeaveFormState> {
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

  void typeChanged(LeaveType type) {
    emit(state.copyWith(type: type));
  }

  void startDateChanged(DateTime date) {
    emit(state.copyWith(
      startDate: date,
      startDateError: null,
      generalError: null,
    ));
  }

  void endDateChanged(DateTime date) {
    emit(state.copyWith(
      endDate: date,
      endDateError: null,
      generalError: null,
    ));
  }

  void reasonChanged(String reason) {
    emit(state.copyWith(
      reason: reason,
      reasonError: null,
      generalError: null,
    ));
  }

  Future<void> submit({
    required int availableDays,
    required List<LeaveRequest> existingRequests,
  }) async {
    final isOnline = await _connectivityService.isOnline;
    if (!isOnline) {
      emit(state.copyWith(
        generalError: 'Internet connection is required to submit leave requests.',
        isOffline: true,
      ));
      return;
    }

    if (state.startDate == null) {
      emit(state.copyWith(startDateError: 'Please select a start date.'));
      return;
    }
    if (state.endDate == null) {
      emit(state.copyWith(endDateError: 'Please select an end date.'));
      return;
    }

    final todayCompanyDate = _calendar.toCompanyDateTime(_clock.now());

    // Local validation via LeaveValidator
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

    emit(state.copyWith(
      status: LeaveFormStatus.submitting,
      clearErrors: true,
    ));

    final result = await _leaveRepository.applyLeave(
      type: state.type,
      startDate: state.startDate!,
      endDate: state.endDate!,
      reason: state.reason,
    );

    if (result is Success<LeaveRequest>) {
      emit(state.copyWith(status: LeaveFormStatus.success));
    } else if (result is FailureResult<LeaveRequest>) {
      emit(state.copyWith(
        status: LeaveFormStatus.failure,
        generalError: result.failure.message,
      ));
    }
  }
}
