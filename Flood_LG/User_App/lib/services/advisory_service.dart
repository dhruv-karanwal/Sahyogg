import 'package:firebase_database/firebase_database.dart';

class AdvisoryService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  /// Stream of current advisory data from 'advisories/current'.
  Stream<DatabaseEvent> get advisoryStream {
    return _dbRef.child('advisories/current').onValue;
  }

  /// Stream of all past advisories from 'advisories/history'.
  /// Ordered by timestamp is best handled on client side for flexibility, 
  /// or we can use orderByChild('timestamp') here.
  Query get advisoryHistoryQuery {
    return _dbRef.child('advisories/history');
  }
}
