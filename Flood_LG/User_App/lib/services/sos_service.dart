import 'package:cloud_firestore/cloud_firestore.dart';

class SOSService {
  final CollectionReference _sosRef =
      FirebaseFirestore.instance.collection('rescue_requests');

  // Simple static ID for session persistence without Auth
  static final String _currentUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';

  String get currentUserId => _currentUserId;

  /// Sends a new SOS request and returns the reference.
  Future<String> sendSOS({
    required double latitude,
    required double longitude,
    required String userId,
    String description = 'Emergency SOS triggered by user.',
  }) async {
    try {
      final docRef = await _sosRef.add({
        'userId': userId,
        'location': 'User SOS Location',
        'lat': latitude,
        'lng': longitude,
        'status': 'PENDING',
        'priority': 'High',
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'MOBILE_SOS',
      });
      return docRef.id;
    } catch (e) {
      print('Error sending SOS: $e');
      rethrow;
    }
  }

  /// Stream of a specific SOS request.
  Stream<DocumentSnapshot> listenToSOS(String docId) {
    return _sosRef.doc(docId).snapshots();
  }
}
