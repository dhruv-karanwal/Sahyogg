import 'package:cloud_firestore/cloud_firestore.dart';

class SOSManagementService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String disasterType;

  SOSManagementService(this.disasterType);

  Future<void> cleanupSOSRequests() async {
    print('Starting SOS Cleanup...');
    try {
      final snapshot = await _db.collection('Disasters').doc(disasterType).collection('rescue_requests').get();
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
        final docRef = _db.collection('Disasters').doc(disasterType).collection('rescue_requests').doc();
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

  Future<void> migrateOldSOSToNewPriorityTiers() async {
    print('Starting SOS Migration to 4-Tier System...');
    try {
      final snapshot = await _db.collection('rescue_requests').get();
      final batch = _db.batch();
      int migratedCount = 0;

      // Duplicate dictionaries locally for the standalone migration script
      const List<String> redKeywords = [
        'medical', 'heart', 'attack', 'bleeding', 'blood', 'dying', 'dead', 'death',
        'trapped', 'stuck', 'drowning', 'water rising', 'fire', 'burn', 'breathe',
        'choking', 'unconscious', 'fainted', 'seizure', 'casualty', 'severe',
        'critical', 'emergency', 'crushed', 'collapse'
      ];

      const List<String> orangeKeywords = [
        'pregnant', 'baby', 'child', 'infant', 'elderly', 'old man', 'old woman',
        'senior', 'disabled', 'wheelchair', 'stranded', 'isolated', 'running out',
        'starving', 'dehydrated', 'fever', 'infection', 'asthma', 'inhaler',
        'insulin', 'property damage', 'roof collapse'
      ];

      const List<String> yellowKeywords = [
        'food', 'water', 'hungry', 'thirsty', 'ration', 'supply', 'medicine',
        'pill', 'prescription', 'cold', 'freezing', 'blanket', 'shelter', 'roof',
        'power', 'electricity', 'battery', 'charge', 'generator', 'evacuate',
        'flooded', 'damage', 'injured', 'sprain', 'cut'
      ];

      const List<String> whiteKeywords = [
        'info', 'information', 'update', 'road', 'blocked', 'highway', 'street',
        'bridge', 'when', 'how', 'where', 'status', 'safe', 'clear', 'weather',
        'rain', 'storm', 'wind', 'alert', 'notice', 'query', 'check', 'report',
        'tree down', 'pothole', 'traffic', 'general'
      ];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final priority = data['priority'] as String?;
        final pUpper = priority?.toUpperCase();

        // If the priority is not already one of the exact 4 tiers, we must migrate it.
        // We also migrate if it's completely missing.
        if (pUpper != 'RED' && pUpper != 'ORANGE' && pUpper != 'YELLOW' && pUpper != 'WHITE') {
          final description = data['description'] as String? ?? '';
          final emergencyType = data['emergencyType'] as String? ?? '';
          
          final textToAnalyze = '$description $emergencyType'.toLowerCase();
          
          String newPriority = 'WHITE';
          String newTag = 'Unclassified Info';

          // Basic triage logic
          if (textToAnalyze.isEmpty) {
            newPriority = 'WHITE';
            newTag = 'General Context';
          } else {
             bool found = false;
             for (final k in redKeywords) {
                if (textToAnalyze.contains(k)) {
                  newPriority = 'RED'; newTag = 'Life-Threatening'; found = true; break;
                }
             }
             if (!found) {
                for (final k in orangeKeywords) {
                  if (textToAnalyze.contains(k)) {
                     newPriority = 'ORANGE'; newTag = 'High Urgency'; found = true; break;
                  }
                }
             }
             if (!found) {
                for (final k in yellowKeywords) {
                  if (textToAnalyze.contains(k)) {
                     newPriority = 'YELLOW'; newTag = 'Moderate Relieve'; found = true; break;
                  }
                }
             }
             if (!found) {
                for (final k in whiteKeywords) {
                  if (textToAnalyze.contains(k)) {
                     newPriority = 'WHITE'; newTag = 'Information/General'; break;
                  }
                }
             }
          }

          batch.update(doc.reference, {
            'priority': newPriority,
            'triageTag': newTag,
            'legacyPriority': priority, // Keep the old one just in case
          });
          migratedCount++;
        }
      }

      if (migratedCount > 0) {
        await batch.commit();
        print('Migration Complete. Successfully upgraded $migratedCount old tickets.');
      } else {
        print('Migration Complete. No legacy tickets found.');
      }
      
    } catch (e) {
      print('Error migrating requests: $e');
      rethrow;
    }
  }
}