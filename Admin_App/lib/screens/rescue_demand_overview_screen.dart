import 'package:flutter/material.dart';
import '../controllers/lg_controller.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;

class RescueDemandOverviewScreen extends StatefulWidget {
  final LGController lgController;
  final List<Map<String, dynamic>> requests; // Pass data from parent

  const RescueDemandOverviewScreen({
    super.key,
    required this.lgController,
    required this.requests,
  });

  @override
  State<RescueDemandOverviewScreen> createState() => _RescueDemandOverviewScreenState();
}

class _RescueDemandOverviewScreenState extends State<RescueDemandOverviewScreen> {
  late List<AreaSummary> _summaries;

  @override
  void initState() {
    super.initState();
    _aggregateData();
  }

  void _aggregateData() {
    final Map<String, AreaSummary> tempMap = {};

    for (var req in widget.requests) {
      // Simple extraction: use the location string before the first comma as 'Area'
      // e.g. "Aluva Bridge, Kochi" -> "Aluva Bridge"
      final String rawLoc = req['location'] ?? 'Unknown';
      final String areaName = rawLoc.split(',').first.trim();
      
      // Attempt to extract lat/lg from first request of area for casting center
      final double lat = req['lat'] ?? 0.0;
      final double lng = req['lng'] ?? 0.0;

      if (!tempMap.containsKey(areaName)) {
        tempMap[areaName] = AreaSummary(name: areaName, lat: lat, lng: lng);
      }

      final summary = tempMap[areaName]!;
      summary.totalRequests++;
      
      if (req['status'] == 'PENDING') {
        summary.pendingCount++;
        // Track oldest pending (simulate with simple string parsing or just count for now)
      }

      final priority = req['priority'] ?? 'Medium';
      if (priority == 'High' || req['description'].toString().toLowerCase().contains('medical')) {
        summary.highPriorityCount++;
      }
    }

    _summaries = tempMap.values.toList();
    
    // Assign Overall Priority
    for (var s in _summaries) {
      if (s.highPriorityCount > 0 || s.totalRequests > 5) {
        s.overallPriority = 'High';
      } else if (s.pendingCount > 3 || s.totalRequests > 2) {
        s.overallPriority = 'Medium';
      } else {
        s.overallPriority = 'Low';
      }
    }
  }

  Future<void> _castArea(AreaSummary area) async {
    try {
      await widget.lgController.sendAreaSummary(
        areaName: area.name,
        lat: area.lat,
        lng: area.lng,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Casting ${area.name} Demand to LG'),
            backgroundColor: _getPriorityColor(area.overallPriority),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cast to LG'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High': return Colors.red;
      case 'Medium': return Colors.orange;
      case 'Low': return Colors.yellow;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Rescue Demand Overview'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [theme.colorScheme.surface, theme.scaffoldBackgroundColor],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
               Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: Colors.blue.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(8),
                     border: Border.all(color: Colors.blue.withOpacity(0.3)),
                   ),
                   child: const Row(
                     children: [
                       Icon(Icons.info_outline, color: Colors.blue, size: 20),
                       SizedBox(width: 8),
                       Expanded(
                         child: Text(
                           'Based on reported SOS requests. Helps identify high-demand zones.',
                           style: TextStyle(color: Colors.white70, fontSize: 12),
                         ),
                       ),
                     ],
                   ),
                 ),
               ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _summaries.length,
                  itemBuilder: (context, index) {
                    final area = _summaries[index];
                    final color = _getPriorityColor(area.overallPriority);
                    
                    return Card(
                      color: Colors.white.withOpacity(0.05),
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: color.withOpacity(0.3)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  area.name,
                                  style: google_fonts.GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: color),
                                  ),
                                  child: Text(
                                    area.overallPriority.toUpperCase(),
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildMetric('Total SOS', area.totalRequests.toString(), Colors.white),
                                _buildMetric('Pending', area.pendingCount.toString(), Colors.orange),
                                _buildMetric('Critical', area.highPriorityCount.toString(), Colors.red),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _castArea(area),
                                icon: const Icon(Icons.rocket_launch, size: 18),
                                label: const Text('Cast Area to Liquid Galaxy'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color.withOpacity(0.2),
                                  foregroundColor: color,
                                  side: BorderSide(color: color.withOpacity(0.5)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

class AreaSummary {
  final String name;
  final double lat;
  final double lng;
  int totalRequests = 0;
  int pendingCount = 0;
  int highPriorityCount = 0;
  String overallPriority = 'Low';

  AreaSummary({required this.name, required this.lat, required this.lng});
}
