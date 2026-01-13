import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/advisory_service.dart';

class AdvisoryScreen extends StatelessWidget {
  const AdvisoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Advisory History')),
      body: StreamBuilder<DatabaseEvent>(
        stream: AdvisoryService().advisoryHistoryQuery.onValue,
        builder: (context, snapshot) {
          // Error state
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final event = snapshot.data;
          
          if (event == null || event.snapshot.value == null) {
            return const Center(
              child: Text(
                'No advisory history',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final rawData = event.snapshot.value;
          List<Map<dynamic, dynamic>> advisoryList = [];

          if (rawData != null && rawData is Map) {
             try {
               final mapData = rawData as Map<dynamic, dynamic>;
               mapData.forEach((key, value) {
                  if (value is Map) {
                     advisoryList.add(value as Map<dynamic, dynamic>);
                  } else {
                     // Attempt to convert if it's Object?
                     try {
                        advisoryList.add(Map<dynamic, dynamic>.from(value as Map));
                     } catch (e) {
                        print('Skipping invalid advisory entry: $value');
                     }
                  }
               });
             } catch (e) {
               print('Error parsing advisory history: $e');
             }
          }

          if (advisoryList.isEmpty) {
             return const Center(child: Text('No advisory history found.'));
          }

          // Sort by timestamp descending (newest first)
          advisoryList.sort((a, b) {
             int tA = int.tryParse(a['timestamp'].toString()) ?? 0;
             int tB = int.tryParse(b['timestamp'].toString()) ?? 0;
             return tB.compareTo(tA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: advisoryList.length,
            itemBuilder: (context, index) {
              final data = advisoryList[index];
              return _buildAdvisoryCard(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildAdvisoryCard(Map<dynamic, dynamic> data) {
    final String message = (data['message'] ?? '').toString();
    final String type = (data['type'] ?? 'Information').toString();

    // Parse timestamp robustly
    final dynamic tsRaw = data['timestamp'];
    int timestamp = 0;
    if (tsRaw is int) {
      timestamp = tsRaw;
    } else if (tsRaw is num) {
      timestamp = tsRaw.toInt();
    } else if (tsRaw is String) {
      timestamp = int.tryParse(tsRaw) ?? 0;
    }

    DateTime updatedAt = DateTime.now();
    if (timestamp > 0) {
      if (timestamp < 1000000000000) {
        timestamp = timestamp * 1000;
      }
      updatedAt = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
    }
    
    // Formatting date helper
    final timeStr = "${updatedAt.hour}:${updatedAt.minute.toString().padLeft(2, '0')}";
    final dateStr = "${updatedAt.day}/${updatedAt.month}/${updatedAt.year}";

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: _typeColor(type),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  type.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _typeColor(type),
                  ),
                ),
                const Spacer(),
                 Text(
                  '$dateStr $timeStr',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Warning':
        return Colors.orange;
      case 'Evacuation':
        return Colors.red;
      case 'All Clear':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}
