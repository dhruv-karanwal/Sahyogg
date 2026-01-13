import 'package:cloud_firestore/cloud_firestore.dart';

class SOSService {
  final CollectionReference _sosRef =
      FirebaseFirestore.instance.collection('rescue_requests');

  /// Stream of all SOS requests for Admin.
  Stream<QuerySnapshot> get allSOSStream {
    return _sosRef.orderBy('createdAt', descending: true).snapshots();
  }

  /// Updates the status of an SOS request.
  Future<void> updateSOSStatus(String id, String status) async {
    try {
      await _sosRef.doc(id).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating SOS status: $e');
      rethrow;
    }
  }
}
