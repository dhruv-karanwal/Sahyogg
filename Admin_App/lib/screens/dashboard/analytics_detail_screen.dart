import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsDetailScreen extends StatelessWidget {
  final String type;

  const AnalyticsDetailScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(type),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (type == 'Active Shelters') {
      return Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('safe_zones')
              .where('status', isEqualTo: 'ACTIVE')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('No active shelters found.', style: TextStyle(color: Colors.grey)));
            }

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final name = data['name'] ?? 'Unknown Shelter';
                final category = data['category'] ?? 'General';
                final capacity = data['capacity']?.toString() ?? 'N/A';
                final city = data['city'] ?? '';
                
                return Card(
                  color: const Color(0xFF141A26),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withOpacity(0.1))),
                  child: ListTile(
                    onTap: () => _showEditShelterDialog(context, docs[index].id, data),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.greenAccent,
                      child: Icon(Icons.shield_outlined, color: Colors.black),
                    ),
                    title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$category • Capacity: $capacity', style: TextStyle(color: Colors.grey[400])),
                        if (city.isNotEmpty) Text('Location: $city', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: const Text('Active', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    }

    if (type == 'High Risk Zones') {
      return Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('rescue_requests').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Error loading data', style: TextStyle(color: Colors.red)));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final docs = snapshot.data!.docs;
            
            // Group by District -> List of Requests
            final Map<String, List<DocumentSnapshot>> zonedRequests = {};
            
            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              // Use District as the primary View Zone, fallback to City
              String zoneName = data['district'] ?? data['city'] ?? 'Unknown Zone';
              if (data['city'] != null && data['district'] != null) {
                  zoneName = '${data['city']}, ${data['district']}';
              }
              
              if (!zonedRequests.containsKey(zoneName)) {
                zonedRequests[zoneName] = [];
              }
              zonedRequests[zoneName]!.add(doc);
            }

            // Sort zones by request count (descending)
            final sortedZones = zonedRequests.entries.toList()
              ..sort((a, b) => b.value.length.compareTo(a.value.length));

            if (sortedZones.isEmpty) {
               return const Center(child: Text('No high risk zones detected.', style: TextStyle(color: Colors.grey)));
            }

            return ListView.builder(
              itemCount: sortedZones.length,
              itemBuilder: (context, index) {
                final zoneName = sortedZones[index].key;
                final requests = sortedZones[index].value;
                final count = requests.length;
                final isCritical = count > 10;

                return Card(
                  color: const Color(0xFF141A26),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), 
                    side: BorderSide(color: isCritical ? Colors.red.withOpacity(0.5) : Colors.transparent)
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCritical ? Colors.red.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: isCritical ? Colors.red : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        zoneName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        isCritical ? 'Critical Risk Zone' : 'Moderate Risk Zone',
                        style: TextStyle(color: isCritical ? Colors.redAccent : Colors.orangeAccent, fontSize: 12),
                      ),
                      children: [
                        Container(
                          color: Colors.black12,
                          constraints: const BoxConstraints(maxHeight: 250), // Limit height to avoid massive lists
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: requests.length,
                            itemBuilder: (context, i) {
                              final req = requests[i].data() as Map<String, dynamic>;
                              final area = req['area'] ?? 'Unknown Area';
                              final desc = req['description'] ?? 'No Description';
                              final status = req['status'] ?? 'PENDING';
                              
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                title: Text(area, style: const TextStyle(color: Colors.white70)),
                                subtitle: Text(
                                  '$desc\nStatus: $status',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                  maxLines: 2, 
                                  overflow: TextOverflow.ellipsis
                                ),
                                trailing: Icon(
                                  Icons.circle, 
                                  size: 8, 
                                  color: status == 'PENDING' ? Colors.red : Colors.green
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextButton.icon(
                            onPressed: () {
                              // Navigate to map or detailed list if needed
                            }, 
                            icon: const Icon(Icons.map, size: 16),
                            label: const Text('View on Map'),
                          ),
                        )
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

    if (type == 'SOS Requests') {
      return Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('rescue_requests').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Error loading data', style: TextStyle(color: Colors.red)));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final docs = snapshot.data!.docs;
            
            // 1. Filter & Aggregate Data
            final areaCounts = <String, int>{};
            
            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              // Filter active requests if needed, or count all (currently counting all for analytics)
              // String status = data['status'] ?? 'PENDING';
              
              String area = data['area'] ?? data['city'] ?? 'Unknown Area';
              areaCounts[area] = (areaCounts[area] ?? 0) + 1;
            }

            // 2. Sort by Count (Descending)
            final sortedAreas = areaCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            // 3. Take Top 5 for Chart
            final top5 = sortedAreas.take(5).toList();

            return Column(
              children: [
                // --- Chart Section ---
                Card(
                  color: const Color(0xFF141A26),
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Top Affected Areas', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: (top5.isNotEmpty ? top5.first.value.toDouble() : 10) * 1.2,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (_) => Colors.blueGrey,
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    return BarTooltipItem(
                                      '${top5[groupIndex].key}\n',
                                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      children: [
                                        TextSpan(
                                          text: '${rod.toY.toInt()} Requests',
                                          style: const TextStyle(color: Colors.yellowAccent),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >= top5.length) return const Text('');
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          top5[value.toInt()].key.split(' ').first, // Show first word of area
                                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: top5.asMap().entries.map((entry) {
                                return BarChartGroupData(
                                  x: entry.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: entry.value.value.toDouble(),
                                      color: Colors.redAccent,
                                      width: 16,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- List Section ---
                Row(
                  children: [
                    const Text('High Priority Zones', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                      child: Text('${sortedAreas.length} Areas', style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: sortedAreas.length,
                    itemBuilder: (context, index) {
                      final area = sortedAreas[index].key;
                      final count = sortedAreas[index].value;
                      
                      return Card(
                        color: const Color(0xFF141A26),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: index < 3 ? Colors.red.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: index < 3 ? Colors.red : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(area, style: const TextStyle(color: Colors.white)),
                          subtitle: Text('Critical Priority', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$count',
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              const Text('SOS', style: TextStyle(color: Colors.redAccent, fontSize: 10)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
    
    // Default Content for other types
    return Column(
      children: [
         Card(
           color: const Color(0xFF141A26),
           child: Padding(
             padding: const EdgeInsets.all(16.0),
             child: SizedBox(
               height: 300,
               child: _buildChart(type),
             ),
           ),
         ),
         const SizedBox(height: 20),
         const Text(
           'Advanced analytics and historical trends will appear here.',
           style: TextStyle(color: Colors.grey),
           textAlign: TextAlign.center,
         ),
      ],
    );
  }

  void _showEditShelterDialog(BuildContext context, String docId, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Shelter';
    final currentCapacity = data['capacity']?.toString() ?? '0';
    final TextEditingController capacityController = TextEditingController(text: currentCapacity);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2738),
        title: Text('Manage $name', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Update Capacity', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: capacityController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF141A26),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: const Icon(Icons.people, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Status', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                 // Close Shelter Logic
                 Navigator.pop(context);
                 await FirebaseFirestore.instance.collection('safe_zones').doc(docId).update({
                   'status': 'CLOSED',
                   'visibleToPublic': false,
                   'lastUpdated': FieldValue.serverTimestamp(),
                 });
                 if(context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shelter marked as CLOSED')));
                 }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.2),
                foregroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: const BorderSide(color: Colors.red),
              ),
              icon: const Icon(Icons.block),
              label: const Text('Close Shelter'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Update Capacity Logic
              final newCap = int.tryParse(capacityController.text) ?? 0;
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('safe_zones').doc(docId).update({
                'capacity': newCap,
                'lastUpdated': FieldValue.serverTimestamp(),
              });
              if(context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Capacity updated successfully')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(String type) {
    // Placeholder chart logic
    if (type == 'SOS Requests') {
      return LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 3),
                FlSpot(1, 1),
                FlSpot(2, 4),
                FlSpot(3, 2),
                FlSpot(4, 5),
                FlSpot(5, 6),
              ],
              isCurved: true,
              color: Colors.redAccent,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: Colors.redAccent.withOpacity(0.2)),
            ),
          ],
        ),
      );
    }
    
    return Center(
      child: Text(
        'Chart for $type',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
