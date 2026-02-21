import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

Future<void> seedCycloneSafeZones() async {
  try {
    debugPrint('Seeding Cyclone Amphan safe zones...');
    
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    
    final safeZonesCollection = db.collection('Disasters').doc('cyclone_amphan').collection('safe_zones');
    
    // West Bengal Safe Zones for Cyclone Amphan
    final safeZones = [
      {
        'id': 'sz_bengal_1',
        'name': 'Kolkata Central Relief Camp',
        'lat': 22.5726,
        'lng': 88.3639,
        'capacity': 500,
        'category': 'Relief Camp',
        'type': 'School',
        'status': 'ACTIVE',
      },
      {
        'id': 'sz_bengal_2',
        'name': 'Howrah Station Emergency Shelter',
        'lat': 22.5843,
        'lng': 88.3433,
        'capacity': 1000,
        'category': 'Relief Camp',
        'type': 'Railway Station',
        'status': 'ACTIVE',
      },
      {
        'id': 'sz_bengal_3',
        'name': 'South 24 Parganas Medical Facility',
        'lat': 22.2536,
        'lng': 88.3476,
        'capacity': 300,
        'category': 'Medical Facility',
        'type': 'Hospital',
        'status': 'ACTIVE',
      },
      {
        'id': 'sz_bengal_4',
        'name': 'Sundarbans Coastal Shelter',
        'lat': 21.9497,
        'lng': 89.1833,
        'capacity': 800,
        'category': 'Relief Camp',
        'type': 'Coastal Shelter',
        'status': 'ACTIVE',
      },
      {
        'id': 'sz_bengal_5',
        'name': 'Haldia Multipurpose Cyclone Shelter',
        'lat': 22.0667,
        'lng': 88.0698,
        'capacity': 1500,
        'category': 'Relief Camp',
        'type': 'Cyclone Shelter',
        'status': 'ACTIVE',
      },
      {
        'id': 'sz_bengal_6',
        'name': 'Digha Safe Zone',
        'lat': 21.6266,
        'lng': 87.5273,
        'capacity': 600,
        'category': 'Relief Camp',
        'type': 'School',
        'status': 'ACTIVE',
      },
      {
        'id': 'sz_bengal_7',
        'name': 'Kharagpur Relief Center',
        'lat': 22.3302,
        'lng': 87.3237,
        'capacity': 450,
        'category': 'Relief Camp',
        'type': 'Community Hall',
        'status': 'ACTIVE',
      },
      {
        'id': 'sz_bengal_8',
        'name': 'Medinipur Medical Camp',
        'lat': 22.4257,
        'lng': 87.3199,
        'capacity': 250,
        'category': 'Medical Facility',
        'type': 'Hospital',
        'status': 'ACTIVE',
      }
    ];

    for (final sz in safeZones) {
      final docRef = safeZonesCollection.doc(sz['id'].toString());
      batch.set(docRef, sz);
    }
    
    // Migrate old Kerala safe zones
    debugPrint('Migrating Kerala safe zones...');
    final oldSafeZones = await db.collection('safe_zones').get();
    final keralaCollection = db.collection('Disasters').doc('flood_kerala').collection('safe_zones');
    for (final doc in oldSafeZones.docs) {
      final newDocRef = keralaCollection.doc(doc.id);
      batch.set(newDocRef, doc.data());
    }
    
    await batch.commit();
    debugPrint('Successfully seeded and migrated all safe zones!');
  } catch (e) {
    debugPrint('Error seeding safe zones: $e');
  }
}
