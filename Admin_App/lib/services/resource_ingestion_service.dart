import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class ResourceIngestionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Pune Railway Station: 18.5284, 73.8738
  static const double baseLat = 18.5284;
  static const double baseLng = 73.8738;

  List<Map<String, dynamic>> generateDummyResources() {
    final List<Map<String, dynamic>> resources = [];
    final types = ['safe_zone', 'food', 'medical', 'shelter'];
    final names = {
      'safe_zone': ['Sassoon General Hospital Shelter', 'Pune Station Relief Camp', 'Regional Safe House'],
      'food': ['Bhartiya Jalpan Food Drop', 'Station Canteen Relief', 'NGO Food Drive Area'],
      'medical': ['Ruby Hall Clinic (Emergency)', 'Railway Station First Aid', 'Mobile Medical Van'],
      'shelter': ['Osho Ashram Temporary Shelter', 'Pune Municipal School Shelter', 'Local Community Hall']
    };

    final random = Random();

    final itemPool = {
      'safe_zone': ['General Relief Cache', 'Evacuation Kits', 'Rations'],
      'food': ['Hot Meals', 'Drinking Water', 'Rice Bags', 'Biscuits'],
      'medical': ['First Aid Kits', 'Bandages', 'Antibiotics', 'Sanitizers'],
      'shelter': ['Blankets', 'Sleeping Mats', 'Tents', 'Torches']
    };

    for (int i = 0; i < 20; i++) {
      final String type = types[random.nextInt(types.length)];
      final List<String> typeNames = names[type]!;
      final String name = typeNames[random.nextInt(typeNames.length)] + ' #${random.nextInt(100)}';

      final String actionType = random.nextBool() ? 'Pickup Available' : 'Delivery Needed';
      final List<String> typeItems = itemPool[type]!;
      final List<String> items = [];
      int itemCount = random.nextInt(3) + 1; // 1 to 3 items
      for (int j = 0; j < itemCount; j++) {
        String item = typeItems[random.nextInt(typeItems.length)];
        if (!items.contains(item)) items.add(item);
      }

      // Slight offset to cluster them around Pune Railway Station (within ~3-5km radius)
      final double latOffset = (random.nextDouble() - 0.5) * 0.05;
      final double lngOffset = (random.nextDouble() - 0.5) * 0.05;

      resources.add({
        'name': name,
        'type': type,
        'latitude': double.parse((baseLat + latOffset).toStringAsFixed(5)),
        'longitude': double.parse((baseLng + lngOffset).toStringAsFixed(5)),
        'timestamp': FieldValue.serverTimestamp(),
        'actionType': actionType,
        'items': items,
      });
    }

    return resources;
  }

  Future<int> ingestPuneResources() async {
    int addedCount = 0;
    // Volunteer app specifically queries the root collection "resource_points"
    final collection = _firestore.collection('resource_points');
    final resources = generateDummyResources();

    for (final res in resources) {
      await collection.add(res);
      addedCount++;
    }

    return addedCount;
  }
}
