import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/safe_zones_data.dart'; // Import the newly generated 80+ safe zones

class SafeZoneIngestionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String disasterType;

  SafeZoneIngestionService(this.disasterType);

  Future<int> ingestSafeZones() async {
    int addedCount = 0;
    final collection = _firestore.collection('Disasters').doc(disasterType).collection('safe_zones');
    
    // Get the 21+ zones specific to this disaster, default to empty if not found
    final zonesToDeploy = safeZonesData[disasterType] ?? [];

    for (var zone in zonesToDeploy) {
      final docId = zone['id'] as String;
      
      // key-based deduplication
      final docRef = collection.doc(docId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // Add timestamp
        final data = Map<String, dynamic>.from(zone);
        data['timestamp'] = FieldValue.serverTimestamp();
        data['createdBy'] = 'ANTIGRAVITY_AGENT';
        
        await docRef.set(data);
        addedCount++;
      }
    }
    return addedCount;
  }
}