import 'package:cloud_firestore/cloud_firestore.dart';

class SafeZoneService {
  final CollectionReference _safeZonesRef =
      FirebaseFirestore.instance.collection('safe_zones');

  /// Stream of public safe zones (visibleToPublic == true).
  Stream<QuerySnapshot> get publicSafeZonesStream {
    return _safeZonesRef
        .where('visibleToPublic', isEqualTo: true)
        .snapshots();
  }
}
