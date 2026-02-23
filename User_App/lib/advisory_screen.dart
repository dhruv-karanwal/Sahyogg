import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class AdvisoryScreen extends StatefulWidget {
  final String disasterType;
  const AdvisoryScreen({super.key, required this.disasterType});

  @override
  State<AdvisoryScreen> createState() => _AdvisoryScreenState();
}

class _AdvisoryScreenState extends State<AdvisoryScreen> {
  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('advisories')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: loc.get('refresh_advisories') ?? 'Refresh Advisories',
            onPressed: () {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.get('refreshed') ?? 'Refreshed advisories manually')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Current Active Advisory
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('Disasters').doc(widget.disasterType).collection('advisories').doc('current').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return SizedBox.shrink();
              if (!snapshot.hasData || !snapshot.data!.exists) return SizedBox.shrink();

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final isActive = data['isActive'] == true || data['isActive'].toString().toLowerCase() == 'true';
              
              if (!isActive) return SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.get('current_advisory') ?? 'Current Advisory', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    _buildAdvisoryCard(data, isLarge: true),
                  ],
                ),
              );
            },
          ),

          // 1.5 Offline Cached Advisories
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getOfflineAdvisories(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
              final offlineDocs = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(loc.get('offline_broadcasts') ?? 'Offline SMS Broadcasts', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                  ),
                  ...offlineDocs.map((data) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: _buildAdvisoryCard(data, isLarge: false),
                  )),
                  const Divider(height: 32),
                ],
              );
            },
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(loc.get('past_advisories') ?? 'Past Advisories', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),

          // 3. Past Advisories List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Disasters').doc(widget.disasterType).collection('advisories_history')
                  .orderBy('sentAt', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                final docs = snapshot.data?.docs ?? [];
                
                if (docs.isEmpty) {
                  return Center(child: Text(loc.get('no_past_advisories') ?? 'No past advisories found.', style: const TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildAdvisoryCard(data, isLarge: false),
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

  Widget _buildAdvisoryCard(Map<String, dynamic> data, {required bool isLarge}) {
    final String type = (data['type'] ?? 'Information').toString();
    final String message = (data['message'] ?? '').toString();
    final color = _typeColor(type);
    
    // Timestamp handling
    final dynamic tsRaw = data['timestamp'];
    DateTime? date;
    if (tsRaw is Timestamp) {
      date = tsRaw.toDate();
    } else if (tsRaw is int) {
      date = DateTime.fromMillisecondsSinceEpoch(tsRaw);
    } else if (tsRaw is String) {
      date = DateTime.tryParse(tsRaw);
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isLarge ? 20 : 16),
      decoration: BoxDecoration(
        color: isLarge ? color.withOpacity(0.1) : Colors.white,
        border: Border.all(color: isLarge ? color : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isLarge 
          ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: Offset(0, 4))]
          : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: color, size: isLarge ? 24 : 20),
              const SizedBox(width: 8),
              Text(
                type.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: isLarge ? 14 : 12,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              if (date != null)
                Text(
                  "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}",
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
            ],
          ),
          SizedBox(height: isLarge ? 12 : 8),
          Text(
            message,
            style: TextStyle(
              fontSize: isLarge ? 16 : 14,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
        ],
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

  Future<List<Map<String, dynamic>>> _getOfflineAdvisories() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList('offline_advisories') ?? [];
    return cached.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }
}
