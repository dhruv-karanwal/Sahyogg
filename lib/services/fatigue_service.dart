import 'dart:async';
import '../models/volunteer_model.dart';
import 'volunteer_repository.dart';

class FatigueService {
  final VolunteerRepository _repository;
  Timer? _fatigueTimer;
  static const int _dutyLimitHours = 8;

  FatigueService(this._repository);

  void monitorDuty(String volunteerId, VolunteerModel volunteer, Function(String) onLimitReached) {
    _fatigueTimer?.cancel();
    
    if (!volunteer.isOnDuty || volunteer.dutyStartTime == null) return;

    final elapsed = DateTime.now().difference(volunteer.dutyStartTime!);
    final remaining = Duration(hours: _dutyLimitHours) - elapsed;

    if (remaining.isNegative) {
      _triggerLimit(volunteerId, onLimitReached);
    } else {
      _fatigueTimer = Timer(remaining, () {
        _triggerLimit(volunteerId, onLimitReached);
      });
    }
  }

  Future<void> _triggerLimit(String volunteerId, Function(String) onLimitReached) async {
    await _repository.updateDutyStatus(volunteerId, false);
    onLimitReached("You have reached the safe duty limit of 8 hours. You have been toggled off-duty.");
  }

  void dispose() {
    _fatigueTimer?.cancel();
  }
}
