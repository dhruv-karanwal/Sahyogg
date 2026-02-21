import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/lg_controller.dart';
import '../widgets/neu_button.dart';
import 'rescue_demand_overview_screen.dart';

class RescueRequestsScreen extends StatefulWidget {
  final LGController lgController;
  final String disasterType;

  const RescueRequestsScreen({
    super.key, 
    required this.lgController,
    required this.disasterType,
  });

  @override
  State<RescueRequestsScreen> createState() => _RescueRequestsScreenState();
}

class _RescueRequestsScreenState extends State<RescueRequestsScreen> {
  
  Future<void> _acknowledgeRequest(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final String district = data['district'] ?? 'Unknown District';
    final String city = data['city'] ?? 'Unknown City';
    final String area = data['area'] ?? 'Unknown Area';

    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      // 1. Update Request Status
      batch.update(doc.reference, {'status': 'ACKNOWLEDGED'});

      // 2. Decrement Pending Count in Summary
      final summaryRef = db.doc('Disasters/${widget.disasterType}/rescue_summary/$district/cities/$city/areas/$area');
      batch.set(summaryRef, {
        'pending': FieldValue.increment(-1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request Acknowledged & Teams Alerted'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _showOnLG(double lat, double lng) async {
    try {
      await widget.lgController.sendRescueMarker(lat, lng);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rescue Point Sent to Liquid Galaxy'),
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
        title: const Text('Rescue Location', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Loc: ${request['area']}, ${request['city']}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Coords: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Detail: ${request['description']}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                   image: AssetImage('assets/map_placeholder.png'), // Ideally valid asset, but fallback color works
                   fit: BoxFit.cover,
                   opacity: 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, size: 48, color: Colors.redAccent),
                  SizedBox(height: 8),
                  Text('Rescue Location Preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
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
    if (timestamp == null) return 'Just now';
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Rescue Requests'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RescueDemandOverviewScreen(
                lgController: widget.lgController,
                disasterType: widget.disasterType,
                requests: [], 
              )),
            ),
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Rescue Demand Overview',
          ),
          const SizedBox(width: 8),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Disasters').doc(widget.disasterType).collection('rescue_requests')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No rescue requests active.', style: TextStyle(color: Colors.white54)));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  return _buildRequestCard(docs[index]);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(DocumentSnapshot doc) {
    final req = doc.data() as Map<String, dynamic>;
    final isPending = (req['status'] ?? 'PENDING') == 'PENDING';
    final statusColor = isPending ? Colors.red : Colors.green;
    final priority = req['priority'] ?? 'Medium';
    
    // Dynamic Location String
    final location = '${req['area'] ?? 'Unknown Area'}, ${req['city'] ?? 'Unknown City'}';
    
    Color priorityColor;
    switch(priority) {
      case 'High': priorityColor = Colors.red; break;
      case 'Medium': priorityColor = Colors.orange; break;
      case 'Low': priorityColor = Colors.yellow; break;
      default: priorityColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.sos, color: statusColor),
                ),
                 Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              location,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${_formatTimeAgo(req['createdAt'])} • Priority: $priority\n${req['description'] ?? "No description"}',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            trailing: Column( // Use Column for stacking status and acknowledge button
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    req['status'] ?? 'UNKNOWN',
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewOnMap(req, req['lat'], req['lng']),
                        icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                        label: const Text('View'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showOnLG(req['lat'], req['lng']),
                        icon: const Icon(Icons.rocket_launch, size: 18),
                        label: const Text('LG Cast'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade900.withOpacity(0.5),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                 if (isPending) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _acknowledgeRequest(doc),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Acknowledge Request'),
                    ),
                  ),
                ] else ...[
                   const SizedBox(height: 8),
                   Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Last updated by: Control Room', 
                      style: TextStyle(color: Colors.white30, fontSize: 10, fontStyle: FontStyle.italic),
                    ),
                   ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}