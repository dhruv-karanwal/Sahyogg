import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:apps/screens/dashboard/widgets/kpi_card.dart';
import 'package:apps/screens/dashboard/analytics_detail_screen.dart';
import 'package:apps/services/safe_zone_ingestion_service.dart';
import 'package:apps/services/sos_management_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _timeFilter = 'Live'; // Live, 1H, 24H, 7D

  // Firestore Streams
  Stream<QuerySnapshot> get _sosStream =>
      FirebaseFirestore.instance.collection('rescue_requests').snapshots();

  Stream<QuerySnapshot> get _safeZonesStream =>
      FirebaseFirestore.instance.collection('safe_zones').snapshots();

  Stream<QuerySnapshot> get _routesStream => FirebaseFirestore.instance
      .collection('floods')
      .doc('kerela-flood')
      .collection('routes')
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // AppBar is handled by the parent layout or we can have a custom header
      body: CustomScrollView(
        slivers: [
          SliverSafeArea(
            bottom: false,
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildTimeFilters(),
                    const SizedBox(height: 24),
                    _buildKpiGrid(),
                    const SizedBox(height: 24),
                    _buildSmartInsights(),
                    const SizedBox(height: 24),
                    _buildLiveSosFeed(),
                    const SizedBox(height: 24),
                    _buildTopRiskZones(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics & Insights',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Real-time disaster overview',
                style: TextStyle(color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),


      ],
    );
  }

  Widget _buildRiskBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: _sosStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        // Simple risk calculation based on active SOS count
        // You might want to filter active/pending ones only
        final count = snapshot.data!.docs.where((doc) { 
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] as String? ?? '';
            return status != 'RESOLVED'; // Count unresolved
        }).length;

        String level = 'LOW';
        Color color = Colors.green;

        if (count >= 60) {
          level = 'HIGH';
          color = Colors.red;
        } else if (count >= 20) {
          level = 'MEDIUM';
          color = Colors.orange;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.5), blurRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$level RISK',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeFilters() {
    final filters = ['Live', '1H', '24H', '7D'];
    return Row(
      children: [
        _buildRiskBadge(),
        const Spacer(),
        PopupMenuButton<String>(
          initialValue: _timeFilter,
          onSelected: (String value) {
            setState(() {
              _timeFilter = value;
            });
          },
          color: const Color(0xFF141A26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (BuildContext context) {
            return filters.map((String choice) {
              final isSelected = _timeFilter == choice;
              return PopupMenuItem<String>(
                value: choice,
                child: Row(
                  children: [
                    Text(
                      choice,
                      style: TextStyle(
                        color: isSelected ? Colors.tealAccent : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (isSelected) ...[
                      const Spacer(),
                      const Icon(Icons.check, size: 16, color: Colors.tealAccent),
                    ]
                  ],
                ),
              );
            }).toList();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF141A26),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(Icons.filter_list, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adapt grid based on width
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
             _buildSosKpi(),
             _buildRiskZonesKpi(),
             _buildSheltersKpi(),
             _buildBlockedRoutesKpi(),
          ],
        );
      },
    );
  }
  
  // KPI Builders
  Widget _buildSosKpi() {
      return StreamBuilder<QuerySnapshot>(
          stream: _sosStream,
          builder: (context, snapshot) {
              final isLoading = !snapshot.hasData;
              final count = snapshot.data?.docs.length ?? 0;
              // Filter logic for time can be added here
              
              return KpiCard(
                  title: 'Total SOS',
                  value: count.toString(),
                  icon: Icons.sos,
                  color: Colors.redAccent,
                  isLoading: isLoading,
                  onTap: () => _navigateToDetail('SOS Requests'),
              );
          },
      );
  }

  Widget _buildRiskZonesKpi() {
      return StreamBuilder<QuerySnapshot>(
          stream: _sosStream,
          builder: (context, snapshot) {
              final isLoading = !snapshot.hasData;
              int highRiskCount = 0;
              
              if (snapshot.hasData) {
                  // Group by area
                  final Map<String, int> areaCounts = {};
                  for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final area = data['area'] ?? data['city'] ?? 'Unknown';
                      areaCounts[area] = (areaCounts[area] ?? 0) + 1;
                  }
                  
                  highRiskCount = areaCounts.values.where((c) => c >= 10).length;
              }

              return KpiCard(
                  title: 'High Risk Zones',
                  value: highRiskCount.toString(),
                  icon: Icons.warning_amber,
                  color: Colors.orangeAccent,
                  isLoading: isLoading,
                  onTap: () => _navigateToDetail('High Risk Zones'),
              );
          },
      );
  }

  Widget _buildSheltersKpi() {
      return StreamBuilder<QuerySnapshot>(
          stream: _safeZonesStream,
          builder: (context, snapshot) {
              final isLoading = !snapshot.hasData;
              int activeCount = 0;
              
              if (snapshot.hasData) {
                  // Filter for Open/Active shelters
                  activeCount = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data['status'] as String? ?? 'Open';
                      return status == 'Open' || status == 'Active' || status == 'ACTIVE';
                  }).length;
              }

              return KpiCard(
                  title: 'Active Shelters',
                  value: activeCount.toString(),
                  icon: Icons.shield_outlined,
                  color: Colors.greenAccent,
                  isLoading: isLoading,
                  onTap: () => _navigateToDetail('Active Shelters'),
              );
          },
      );
  }

  Widget _buildBlockedRoutesKpi() {
      // Assuming a routes collection exists, or modify path if needed.
      // User mentioned 'floods/routes' where isBlocked==true
      return StreamBuilder<QuerySnapshot>(
          stream: _routesStream,
          builder: (context, snapshot) {
              final isLoading = !snapshot.hasData;
              int blockedCount = 0;
              
              if (snapshot.hasData) {
                  blockedCount = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['isBlocked'] == true;
                  }).length;
              }

              return KpiCard(
                  title: 'Blocked Routes',
                  value: blockedCount.toString(),
                  icon: Icons.remove_road,
                  color: Colors.purpleAccent,
                  isLoading: isLoading,
                  onTap: () => _navigateToDetail('Blocked Routes'),
              );
          },
      );
  }

  void _navigateToDetail(String type) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnalyticsDetailScreen(type: type),
        ),
      );
  }

  Widget _buildSmartInsights() {
      // Generated from all streams combined (simplified for now)
      return StreamBuilder<QuerySnapshot>(
          stream: _sosStream,
          builder: (context, snapshot) {
               if(!snapshot.hasData) return const SizedBox.shrink();
               
               final docs = snapshot.data!.docs;
               final List<Widget> insights = [];
               
               // Logic for insights
               if (docs.length > 50) {
                   insights.add(_buildInsightTile('High SOS Volume Detected', Icons.trending_up, Colors.red));
               }
               
               // Check for recent surge (last hour) - simplified check
               // Real logic would check timestamps
               
               if (insights.isEmpty) {
                   return const SizedBox.shrink();
               }

               return Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                       const Text('Smart Insights', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 12),
                       SingleChildScrollView(
                           scrollDirection: Axis.horizontal,
                           child: Row(children: insights),
                       ),
                   ],
               );
          },
      );
  }
  
  Widget _buildInsightTile(String text, IconData icon, Color color) {
      return Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
              children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
          ),
      );
  }

  Widget _buildLiveSosFeed() {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              const Text('Live SOS Feed', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                  stream: _sosStream, // Should limit to 5 sorted by desc in query ideally
                  builder: (context, snapshot) {
                       if(!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                       if(snapshot.data!.docs.isEmpty) return const Text('No recent SOS requests', style: TextStyle(color: Colors.grey));
                       
                       // Sort client side since stream is all docs (or use orderBy in query)
                       final docs = snapshot.data!.docs;
                       docs.sort((a,b) {
                           // Timestamp comparison
                           final tA = (a.data() as Map)['timestamp'] as Timestamp?;
                           final tB = (b.data() as Map)['timestamp'] as Timestamp?;
                           if(tA == null) return 1; 
                           if(tB == null) return -1;
                           return tB.compareTo(tA);
                       });
                       
                       final latest = docs.take(5).toList();
                       
                       return Container(
                           decoration: BoxDecoration(
                               color: const Color(0xFF141A26),
                               borderRadius: BorderRadius.circular(16),
                           ),
                           child: ListView.separated(
                               padding: EdgeInsets.zero,
                               shrinkWrap: true,
                               physics: const NeverScrollableScrollPhysics(),
                               itemCount: latest.length,
                               separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                               itemBuilder: (context, index) {
                                   final data = latest[index].data() as Map<String, dynamic>;
                                   final area = data['area'] ?? data['city'] ?? 'Unknown Area';
                                   final priority = data['priority'] ?? 'MEDIUM';
                                   final status = data['status'] ?? 'PENDING';
                                   final time = _formatTimestamp(data['timestamp']);
                                   
                                   Color statusColor = Colors.grey;
                                   if (status == 'PENDING') statusColor = Colors.orange;
                                   if (status == 'RESOLVED') statusColor = Colors.green;
                                   
                                   return ListTile(
                                       leading: CircleAvatar(
                                           backgroundColor: Colors.red.withOpacity(0.2),
                                           child: const Icon(Icons.sos, color: Colors.red, size: 18),
                                       ),
                                       title: Text(area, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                       subtitle: Text('$priority • $time', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                       trailing: Container(
                                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                           decoration: BoxDecoration(
                                               color: statusColor.withOpacity(0.2),
                                               borderRadius: BorderRadius.circular(8),
                                               border: Border.all(color: statusColor.withOpacity(0.5)),
                                           ),
                                           child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                       ),
                                   );
                               },
                           ),
                       );
                  },
              ),
          ],
      );
  }
  
  String _formatTimestamp(dynamic timestamp) {
      if (timestamp == null) return 'Just now';
      if (timestamp is Timestamp) {
          final dt = timestamp.toDate();
          return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return 'Just now';
  }

  Widget _buildTopRiskZones() {
       return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              const Text('Top Risk Zones', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                  stream: _sosStream,
                  builder: (context, snapshot) {
                      if(!snapshot.hasData) return const SizedBox.shrink();
                      
                       final Map<String, int> areaCounts = {};
                       for (var doc in snapshot.data!.docs) {
                           final data = doc.data() as Map<String, dynamic>;
                           final area = data['area'] ?? data['city'] ?? 'Unknown';
                           areaCounts[area] = (areaCounts[area] ?? 0) + 1;
                       }
                       
                       var sortedKeys = areaCounts.keys.toList(growable: false)
                        ..sort((k1, k2) => areaCounts[k2]!.compareTo(areaCounts[k1]!));
                        
                       final top5 = sortedKeys.take(5).toList();
                       
                       return SizedBox(
                           height: 120, // Horizontal list height
                           child: ListView.builder(
                               scrollDirection: Axis.horizontal,
                               itemCount: top5.length,
                               itemBuilder: (context, index) {
                                   final area = top5[index];
                                   final count = areaCounts[area]!;
                                   
                                   return Container(
                                       width: 140,
                                       margin: const EdgeInsets.only(right: 12),
                                       padding: const EdgeInsets.all(16),
                                       decoration: BoxDecoration(
                                           gradient: LinearGradient(
                                               begin: Alignment.topLeft,
                                               end: Alignment.bottomRight,
                                               colors: [
                                                   Colors.red.withOpacity(0.2),
                                                   Colors.orange.withOpacity(0.1),
                                               ],
                                           ),
                                           borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                                       ),
                                       child: Column(
                                           crossAxisAlignment: CrossAxisAlignment.start,
                                           mainAxisAlignment: MainAxisAlignment.center,
                                           children: [
                                               Text(area, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                               const SizedBox(height: 8),
                                               Text('$count SOS', style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                Text('Critical', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                                           ],
                                       ),
                                   );
                               },
                           ),
                       );
                  },
              ),
          ],
       );
  }

  Widget _buildQuickActions() {

      return Column(
        children: [
          Row(
              children: [
                  Expanded(child: _buildActionButton('Broadcast Alert', Icons.campaign, Colors.orange, () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Broadcast Alert sent!')));
                  })),
                  const SizedBox(width: 12),
                  Expanded(child: _buildActionButton('Cast to LG', Icons.cast_connected, Colors.blue, () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Casting hotspots to Liquid Galaxy...')));
                  })),
                  const SizedBox(width: 12),
                    Expanded(child: _buildActionButton('Export Report', Icons.download, Colors.green, () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting summary report...')));
                  })),
                  const SizedBox(width: 12),
                  Expanded(child: _buildActionButton('Ingest Data', Icons.cloud_upload, Colors.teal, () async {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingesting authoritative safe zones...')));
                      try {
                        final service = SafeZoneIngestionService();
                        final count = await service.ingestSafeZones();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully ingsted $count safe zones!'), backgroundColor: Colors.green));
                            }
                          } catch (e) {
                             if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ingestion failed: $e'), backgroundColor: Colors.red));
                            }
                          }
                      })),
                  ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildActionButton('Reset SOS DB', Icons.restore, Colors.orange, () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resetting SOS Database...')));
                    try {
                      final service = SOSManagementService();
                      await service.cleanupSOSRequests();
                      await service.seedRealisticSOSData();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SOS Database Cleaned & Rebuilt!'), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                       if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reset failed: $e'), backgroundColor: Colors.red));
                      }
                    }
                  })),
                   const Spacer(flex: 3),
                ],
              ),
            ],
          );
      }
  
  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
      return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                  children: [
                      Icon(icon, color: color, size: 24),
                      const SizedBox(height: 8),
                      Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                  ],
              ),
          ),
      );
  }
}
