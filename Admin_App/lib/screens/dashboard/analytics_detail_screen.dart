import 'package:apps/controllers/ssh_controller.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apps/controllers/lg_controller.dart';

class AnalyticsDetailScreen extends StatefulWidget {
  final String type;
  final String disasterType;
  final LGController? lgController;
  final SSHController? sshController;

  const AnalyticsDetailScreen({
    super.key, 
    required this.type,
    required this.disasterType,
    this.lgController,
    this.sshController,
  });

  @override
  State<AnalyticsDetailScreen> createState() => _AnalyticsDetailScreenState();
}

class _AnalyticsDetailScreenState extends State<AnalyticsDetailScreen> {
  bool _isCasting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.type),
        backgroundColor: Colors.transparent,
        actions: [
          _buildLGConnectionStatus(),
          const SizedBox(width: 16),
        ],
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
  
  Widget _buildLGConnectionStatus() {
    final isConnected = widget.lgController?.isConnected ?? false;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isConnected 
          ? Colors.green.withOpacity(0.2) 
          : Colors.grey.withOpacity(0.2),
        border: Border.all(
          color: isConnected ? Colors.green : Colors.grey,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isConnected ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isConnected ? 'LG' : 'LG',
            style: TextStyle(
              color: isConnected ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (widget.type == 'Active Shelters') {
      return Expanded(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Disasters').doc(widget.disasterType).collection('safe_zones')
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
                          onTap: () => _showShelterActionsDialog(context, docs[index].id, data),
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
            ),
          ],
        ),
      );
    }

    if (widget.type == 'High Risk Zones') {
      return Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('Disasters').doc(widget.disasterType).collection('rescue_requests').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Error loading data', style: TextStyle(color: Colors.red)));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final docs = snapshot.data!.docs;
            
            final Map<String, List<DocumentSnapshot>> zonedRequests = {};
            
            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              String zoneName = data['district'] ?? data['city'] ?? 'Unknown Zone';
              if (data['city'] != null && data['district'] != null) {
                  zoneName = '${data['city']}, ${data['district']}';
              }
              
              if (!zonedRequests.containsKey(zoneName)) {
                zonedRequests[zoneName] = [];
              }
              zonedRequests[zoneName]!.add(doc);
            }

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
                      trailing: IconButton(
                        icon: const Icon(Icons.cast_connected, color: Colors.blue),
                        onPressed: () => _castHighPriorityZoneToLG(zoneName, count),
                      ),
                      children: [
                        Container(
                          color: Colors.black12,
                          constraints: const BoxConstraints(maxHeight: 250),
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

    if (widget.type == 'SOS Requests') {
      return Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('Disasters').doc(widget.disasterType).collection('rescue_requests').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Error loading data', style: TextStyle(color: Colors.red)));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final docs = snapshot.data!.docs;
            
            final areaCounts = <String, int>{};
            
            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              String area = data['area'] ?? data['city'] ?? 'Unknown Area';
              areaCounts[area] = (areaCounts[area] ?? 0) + 1;
            }

            final sortedAreas = areaCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            final top5 = sortedAreas.take(5).toList();

            return Column(
              children: [
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
                                          top5[value.toInt()].key.split(' ').first,
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
    
    return Column(
      children: [
         Card(
           color: const Color(0xFF141A26),
           child: Padding(
             padding: const EdgeInsets.all(16.0),
             child: SizedBox(
               height: 300,
               child: _buildChart(widget.type),
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

  void _showShelterActionsDialog(BuildContext context, String docId, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Shelter';
    final currentCapacity = data['capacity']?.toString() ?? '0';
    final TextEditingController capacityController = TextEditingController(text: currentCapacity);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2738),
        title: Text(name, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _castSingleShelterToLG(docId, data);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(0.2),
                foregroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: const BorderSide(color: Colors.blue),
              ),
              icon: const Icon(Icons.cast_connected),
              label: const Text('Cast to Liquid Galaxy'),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                 Navigator.pop(context);
                 await FirebaseFirestore.instance.collection('Disasters').doc(widget.disasterType).collection('safe_zones').doc(docId).update({
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
              final newCap = int.tryParse(capacityController.text) ?? 0;
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('Disasters').doc(widget.disasterType).collection('safe_zones').doc(docId).update({
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _castSingleShelterToLG(String docId, Map<String, dynamic> data) async {
    if (widget.lgController == null || !widget.lgController!.isConnected) {
      _showErrorSnackBar('Not connected to Liquid Galaxy');
      return;
    }

    setState(() => _isCasting = true);

    try {
      final name = data['name'] ?? 'Shelter';
      final lat = data['latitude'] ?? data['lat'];
      final lng = data['longitude'] ?? data['lng'];
      final capacity = data['capacity'] ?? 'N/A';
      final category = data['category'] ?? 'General';
      final city = data['city'] ?? '';
      
      if (lat == null || lng == null) {
        _showErrorSnackBar('No location data available');
        return;
      }

      final kml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <Placemark>
      <name>$name</name>
      <description>Category: $category | Capacity: $capacity | Location: $city</description>
      <Point>
        <coordinates>$lng,$lat,0</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>''';
      
      await widget.lgController!.sendKMLToSlave(widget.lgController!.firstScreen, kml);
      await widget.lgController!.refreshView(screen: widget.lgController!.firstScreen);
      await widget.lgController!.query(
        'flytoview=<LookAt><longitude>$lng</longitude><latitude>$lat</latitude><range>5000</range><tilt>60</tilt><heading>0</heading></LookAt>'
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name cast to LG!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to cast: $e');
    } finally {
      if (mounted) setState(() => _isCasting = false);
    }
  }

  Future<void> _castHighPriorityZoneToLG(String zoneName, int count) async {
    if (widget.lgController == null || !widget.lgController!.isConnected) {
      _showErrorSnackBar('Not connected to Liquid Galaxy');
      return;
    }

    setState(() => _isCasting = true);

    try {
      final kml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <Placemark>
      <name>HIGH PRIORITY: $zoneName</name>
      <description>This zone has $count SOS requests - CRITICAL ATTENTION REQUIRED</description>
      <Point>
        <coordinates>76.0,10.0,0</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>''';
      
      await widget.lgController!.sendKMLToSlave(widget.lgController!.firstScreen, kml);
      await widget.lgController!.refreshView(screen: widget.lgController!.firstScreen);
      await widget.lgController!.query(
        'flytoview=<LookAt><longitude>76.0</longitude><latitude>10.0</latitude><range>50000</range><tilt>45</tilt><heading>0</heading></LookAt>'
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('High Priority Zone: $zoneName ($count requests) cast to LG!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to cast: $e');
    } finally {
      if (mounted) setState(() => _isCasting = false);
    }
  }
  
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildChart(String type) {
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
      child: Text('Chart for $type', style: const TextStyle(color: Colors.white)),
    );
  }
}