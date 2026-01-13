import 'package:flutter/material.dart';
import '../controllers/lg_controller.dart';
import '../widgets/neu_button.dart';
import 'rescue_demand_overview_screen.dart';

class RescueRequestsScreen extends StatefulWidget {
  final LGController lgController;

  const RescueRequestsScreen({super.key, required this.lgController});

  @override
  State<RescueRequestsScreen> createState() => _RescueRequestsScreenState();
}

class _RescueRequestsScreenState extends State<RescueRequestsScreen> {
  // Mock Data
  final List<Map<String, dynamic>> _requests = [
    {
      'id': '1',
      'location': 'Aluva Bridge, Kochi',
      'lat': 10.1071,
      'lng': 76.3550,
      'time': '5 mins ago',
      'status': 'PENDING',
      'priority': 'High',
      'description': 'Family of 4 stranded on rooftop due to Periyar river overflow.'
    },
    {
      'id': '2',
      'location': 'Chengannur Town, Alappuzha',
      'lat': 9.3183,
      'lng': 76.6100,
      'time': '12 mins ago',
      'status': 'PENDING',
      'priority': 'High',
      'description': 'Elderly couple trapped, water above waist level. Urgent evacuation.'
    },
    {
      'id': '3',
      'location': 'Kaloor Stadium, Kochi',
      'lat': 9.9981,
      'lng': 76.3000,
      'time': '20 mins ago',
      'status': 'PENDING',
      'priority': 'High',
      'description': 'Medical emergency, insulin required immediately for diabetic patient.'
    },
    {
      'id': '4',
      'location': 'Aluva Bridge, Kochi',
      'lat': 10.1085,
      'lng': 76.3565,
      'time': '25 mins ago',
      'status': 'ACKNOWLEDGED',
      'priority': 'Medium',
      'description': 'Water entering first floor, need higher ground transport.'
    },
    {
      'id': '5',
      'location': 'Kuttanad, Alappuzha',
      'lat': 9.4195,
      'lng': 76.4851,
      'time': '30 mins ago',
      'status': 'PENDING',
      'priority': 'High',
      'description': 'Multiple households submerged, 3 children present. Boat required.'
    },
    {
      'id': '6',
      'location': 'Edappally Toll, Kochi',
      'lat': 10.0236,
      'lng': 76.3116,
      'time': '45 mins ago',
      'status': 'PENDING',
      'priority': 'Low',
      'description': 'Vehicles stranded, traffic blocked. Water rising slowly.'
    },
    {
      'id': '7',
      'location': 'Ranni Town, Pathanamthitta',
      'lat': 9.3845,
      'lng': 76.7869,
      'time': '50 mins ago',
      'status': 'ACKNOWLEDGED',
      'priority': 'Medium',
      'description': 'Power outage in relief camp area, need generator support.'
    },
    {
      'id': '8',
      'location': 'Nilambur, Malappuram',
      'lat': 11.2758,
      'lng': 76.2241,
      'time': '1 hour ago',
      'status': 'ACKNOWLEDGED',
      'priority': 'Low',
      'description': 'Road blocked by fallen tree, no immediate danger.'
    },
    {
      'id': '9',
      'location': 'Kaloor Stadium, Kochi',
      'lat': 9.9990,
      'lng': 76.3015,
      'time': '1 hour ago',
      'status': 'ACKNOWLEDGED',
      'priority': 'Medium',
      'description': 'Food and water supply needed for 10 people stuck in apartment.'
    },
    {
      'id': '10',
      'location': 'Chengannur Town, Alappuzha',
      'lat': 9.3195,
      'lng': 76.6120,
      'time': '1.5 hours ago',
      'status': 'PENDING',
      'priority': 'Medium',
      'description': 'Requesting status update on nearby shelter availability.'
    },
  ];

  void _acknowledgeRequest(int index) {
    setState(() {
      _requests[index]['status'] = 'ACKNOWLEDGED';
    });
    // Simulate sync
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request Acknowledged'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
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

  void _viewOnMap(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Rescue Location', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Place: ${request['location']}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Coords: ${request['lat']}, ${request['lng']}', style: const TextStyle(color: Colors.white70)),
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
               _showOnLG(request['lat'], request['lng']);
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
                requests: _requests,
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
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _requests.length,
            itemBuilder: (context, index) {
              final req = _requests[index];
              return _buildRequestCard(req, index);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req, int index) {
    final isPending = req['status'] == 'PENDING';
    final statusColor = isPending ? Colors.red : Colors.green;
    final priority = req['priority'] ?? 'Medium';
    
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
              req['location'],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${req['time']} • Priority: $priority\n${req['description']}',
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
                    req['status'],
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
                        onPressed: () => _viewOnMap(req),
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
                      onPressed: () => _acknowledgeRequest(index),
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
