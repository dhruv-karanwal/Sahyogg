import 'package:cloud_firestore/cloud_firestore.dart';

class SOSManagementService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> cleanupSOSRequests() async {
    print('Starting SOS Cleanup...');
    try {
      final snapshot = await _db.collection('rescue_requests').get();
      final batch = _db.batch();
      int deletedCount = 0;

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
        deletedCount++;
      }

      await batch.commit();
      print('Cleanup Complete. Deleted $deletedCount invalid/dummy records.');
    } catch (e) {
      print('Error during cleanup: $e');
      rethrow;
    }
  }

  Future<void> seedRealisticSOSData() async {
    print('Starting SOS Seeding...');
    try {
      final batch = _db.batch();

      // Realistic scenarios from Kerala Floods 2018
      final List<Map<String, dynamic>> allRequests = [];

      // Helper to generate a cluster of requests
      void addCluster({
        required String district, 
        required String city, 
        required String area, 
        required double baseLat, 
        required double baseLng, 
        required int count,
        required String priority,
        required String emergencyType
      }) {
        for (int i = 0; i < count; i++) {
          // Add small random jitter to coordinates
          double latJitter = (DateTime.now().microsecondsSinceEpoch % 100) / 100000; 
          double lngJitter = (DateTime.now().microsecondsSinceEpoch % 100) / 100000;
          if (i % 2 == 0) latJitter = -latJitter;
          
          allRequests.add({
            "district": district,
            "city": city,
            "area": area,
            "lat": baseLat + latJitter,
            "lng": baseLng + lngJitter,
            "description": "Emergency reported in this sector. Request #$i", // Generic but distinct
            "peopleCount": (i % 5) + 2, // Random 2-7 people
            "emergencyType": emergencyType,
            "priority": priority,
            "status": "PENDING",
            "source": "REPORT_BASED_SIMULATION",
            "confidence": "HIGH",
            "timestamp": DateTime.now().subtract(Duration(minutes: i * 5)),
          });
        }
      }

      // 1. High Impact: Ernakulam (Aluva)
      addCluster(
        district: "Ernakulam", city: "Aluva", area: "Near Aluva Bridge", 
        baseLat: 10.1071, baseLng: 76.3550, count: 18, 
        priority: "HIGH", emergencyType: "TRAPPED"
      );

      // 2. High Impact: Alappuzha (Chengannur)
      addCluster(
        district: "Alappuzha", city: "Chengannur", area: "Pandanad", 
        baseLat: 9.3175, baseLng: 76.6167, count: 15, 
        priority: "HIGH", emergencyType: "MEDICAL"
      );

      // 3. Medium Impact: Alappuzha (Kuttanad)
      addCluster(
         district: "Alappuzha", city: "Kuttanad", area: "Kainakary", 
         baseLat: 9.5333, baseLng: 76.3833, count: 8, 
         priority: "HIGH", emergencyType: "EVACUATION"
      );

      // 4. Low Impact: Pathanamthitta (Ranni)
      addCluster(
         district: "Pathanamthitta", city: "Ranni", area: "Ranni Town", 
         baseLat: 9.3833, baseLng: 76.8000, count: 4, 
         priority: "MEDIUM", emergencyType: "TRAPPED"
      );

       // 5. Low Impact: Thrissur (Chalakudy)
      addCluster(
         district: "Thrissur", city: "Chalakudy", area: "Market Road", 
         baseLat: 10.3070, baseLng: 76.3340, count: 3, 
         priority: "MEDIUM", emergencyType: "EVACUATION"
      );


      for (var req in allRequests) {
        final docRef = _db.collection('rescue_requests').doc();
        batch.set(docRef, {
          ...req,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('Seeding Complete. Added ${allRequests.length} realistic records.');
    } catch (e) {
      print('Error during seeding: $e');
      rethrow;
    }
  }
}