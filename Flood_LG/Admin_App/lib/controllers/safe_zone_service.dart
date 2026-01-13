import 'package:cloud_firestore/cloud_firestore.dart';

class SafeZoneService {
  final CollectionReference _safeZonesRef =
      FirebaseFirestore.instance.collection('safe_zones');

  /// Adds a new safe zone.
  Future<void> addSafeZone({
    required String name,
    required double latitude,
    required double longitude,
    required String category,
    required String type,
    required int capacity,
    required String status,
    bool visibleToPublic = false,
  }) async {
    try {
      await _safeZonesRef.add({
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'category': category,
        'type': type,
        'capacity': capacity,
        'status': status,
        'visibleToPublic': visibleToPublic,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding safe zone: $e');
      rethrow;
    }
  }

  /// Updates an existing safe zone.
  Future<void> updateSafeZone(String id, Map<String, dynamic> data) async {
    try {
      await _safeZonesRef.doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating safe zone: $e');
      rethrow;
    }
  }

  /// Deletes a safe zone.
  Future<void> deleteSafeZone(String id) async {
    try {
      await _safeZonesRef.doc(id).delete();
    } catch (e) {
      print('Error deleting safe zone: $e');
      rethrow;
    }
  }

  /// Stream of all safe zones for Admin management.
  Stream<QuerySnapshot> get allSafeZonesStream {
    return _safeZonesRef.orderBy('updatedAt', descending: true).snapshots();
  }
}
