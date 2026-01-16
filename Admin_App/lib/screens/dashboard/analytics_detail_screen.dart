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
