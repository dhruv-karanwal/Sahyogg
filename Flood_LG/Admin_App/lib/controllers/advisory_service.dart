import 'package:firebase_database/firebase_database.dart';

class AdvisoryService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  /// Sends an advisory to 'advisories/current' path in Realtime Database.
  Future<void> sendAdvisory({
    required String type,
    required String message,
  }) async {
    final advisoryData = {
      'type': type,
      'message': message,
      'isActive': true,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'issuedBy': 'Admin Control Room',
    };

    try {
      // 1. Set as current active advisory
      await _dbRef.child('advisories/current').set(advisoryData);
      
      // 2. Add to history log
      await _dbRef.child('advisories/history').push().set(advisoryData);
      
      print('Advisory sent successfully');
    } catch (e) {
      print('Error sending advisory: $e');
      rethrow;
    }
  }

  /// Clears the current advisory.
  Future<void> clearAdvisory() async {
    try {
      await _dbRef.child('advisories/current').remove();
    } catch (e) {
      print('Error clearing advisory: $e');
      rethrow;
    }
  }
}
