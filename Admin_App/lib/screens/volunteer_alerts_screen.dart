import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/lg_controller.dart';
import '../widgets/neu_button.dart';

class VolunteerAlertsScreen extends StatefulWidget {
  final LGController lgController;

  const VolunteerAlertsScreen({
    super.key, 
    required this.lgController,
  });

  @override
  State<VolunteerAlertsScreen> createState() => _VolunteerAlertsScreenState();
}

class _VolunteerAlertsScreenState extends State<VolunteerAlertsScreen> {
  
  Future<void> _acknowledgeAlert(DocumentSnapshot doc) async {
    try {
      final db = FirebaseFirestore.instance;
      // Update Status
      await db.collection('emergency_alerts').doc(doc.id).update({'status': 'ACKNOWLEDGED'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Volunteer Alert Acknowledged & Resolved'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _showOnLG(double lat, double lng) async {
    try {
      // Reusing the Rescue Marker logic format for volunteer alerts
      await widget.lgController.sendRescueMarker(lat, lng);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Volunteer SOS Point Sent to Liquid Galaxy'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect to LG'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _viewOnMap(Map<String, dynamic> request, double lat, double lng) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Volunteer Distress Location', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Volunteer ID: ${request['volunteerId'] ?? 'Unknown'}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Coords: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Detail: ${request['description'] ?? 'No text provided'}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.red.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade800),
              ),
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, size: 48, color: Colors.redAccent),
                  SizedBox(height: 8),
                  Text('Distress Location Preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
               Navigator.pop(context);
               _showOnLG(lat, lng);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Show on Liquid Galaxy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Volunteer Emergency Alerts', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.grey.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emergency_alerts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('No Active Volunteer Alerts', style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final isCritical = (data['priority'] ?? '').toString().toLowerCase() == 'high';
              final isPending = (data['status'] ?? '').toString().toLowerCase() != 'acknowledged';
              
              var lat = 0.0;
              var lng = 0.0;

              if (data['location'] != null && data['location'] is Map) {
                lat = (data['location']['latitude'] ?? 0.0).toDouble();
                lng = (data['location']['longitude'] ?? 0.0).toDouble();
              } else {
                lat = (data['lat'] ?? 0.0).toDouble();
                lng = (data['lng'] ?? 0.0).toDouble();
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: isPending ? (isCritical ? Colors.red.shade900.withOpacity(0.3) : Colors.orange.shade900.withOpacity(0.3)) : Colors.grey.shade900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isPending ? (isCritical ? Colors.red.shade700 : Colors.orange.shade700) : Colors.transparent,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isPending ? Icons.warning_amber_rounded : Icons.check_circle,
                                color: isPending ? Colors.redAccent : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isPending ? 'CRITICAL - ${data['priority']?.toString().toUpperCase() ?? 'HIGH'}' : 'ACKNOWLEDGED',
                                style: TextStyle(
                                  color: isPending ? Colors.redAccent : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _formatTimeAgo(data['timestamp'] as Timestamp?),
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Volunteer ID: ${data['volunteerId'] ?? 'Unknown'}',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['description'] ?? 'No Description Provided',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: NeuButton(
                              icon: Icons.map,
                              label: 'View\nCoordinates',
                              color: Colors.blue,
                              onPressed: () => _viewOnMap(data, lat, lng),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (isPending)
                            Expanded(
                              child: NeuButton(
                                icon: Icons.check,
                                label: 'Acknowledge\nSecure',
                                color: Colors.green,
                                onPressed: () => _acknowledgeAlert(doc),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
