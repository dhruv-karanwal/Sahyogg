import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/advisory_service.dart';
import '../advisory_screen.dart'; // For navigation

class AdvisoryBanner extends StatefulWidget {
  const AdvisoryBanner({super.key});

  @override
  State<AdvisoryBanner> createState() => _AdvisoryBannerState();
}

class _AdvisoryBannerState extends State<AdvisoryBanner> with SingleTickerProviderStateMixin {
  bool _isCompact = false;
  bool _isVisible = false;
  Timer? _compactTimer;
  Map<dynamic, dynamic>? _lastData;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _compactTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleNewData(Map<dynamic, dynamic>? data) {
    if (data == null) {
      if (_isVisible) {
        setState(() => _isVisible = false);
        _controller.reverse();
      }
      return;
    }

    final dynamic isActiveRaw = data['isActive'];
    bool isActive = false;
    if (isActiveRaw is bool) isActive = isActiveRaw;
    else if (isActiveRaw is String) isActive = isActiveRaw.toLowerCase() == 'true';
    
    if (!isActive) {
      if (_isVisible) {
         setState(() => _isVisible = false);
         _controller.reverse();
      }
      return;
    }

    // Check if it's a new advisory by comparing timestamp or message
    bool isNew = false;
    if (_lastData == null || _lastData!['timestamp'] != data['timestamp']) {
      isNew = true;
    }

    if (isNew) {
      _startTimer();
      _controller.forward();
      setState(() {
        _isVisible = true;
        _isCompact = false; // Show full initially
        _lastData = data;
      });
    }
  }

  void _startTimer() {
    _compactTimer?.cancel();
    _compactTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isVisible) {
        setState(() => _isCompact = true);
      }
    });
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Warning': return Colors.orange;
      case 'Evacuation': return Colors.red;
      case 'All Clear': return Colors.green;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: AdvisoryService().advisoryStream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
           final raw = snapshot.data!.snapshot.value;
           if (raw is Map) {
             // Defer state update to next frame if needed, but here we just read for the build
             // Actually, we need to trigger the side effects (timer) only when data CHANGES.
             // StreamBuilder rebuilds on data. We can check diff here?
             // A cleaner way for the timer logic is to use a listener outside build, but StreamBuilder is standard.
             // Let's rely on the previous logic 'isNew' check. 
             // We'll call _handleNewData in a post-frame callback if it's new, 
             // OR just handle the UI rendering here and manage timer via a separate listener? 
             // Let's stick to a simpler approach: 
             // Logic in build is risky for side-effects. 
             // Let's use the StreamBuilder to just get data, and use `didUpdateWidget` or similar? No.
             // Best is to listen in initState. 
             // BUT for now, let's keep it simple: 
             // We will wrap the widget logic.
             WidgetsBinding.instance.addPostFrameCallback((_) {
                _handleNewData(raw as Map<dynamic, dynamic>);
             });
           }
        } else {
           WidgetsBinding.instance.addPostFrameCallback((_) {
             _handleNewData(null);
           });
        }

        if (!_isVisible || _lastData == null) return const SizedBox.shrink();

        final type = (_lastData!['type'] ?? 'Information').toString();
        final message = (_lastData!['message'] ?? '').toString();
        final color = _getTypeColor(type);

        return SizeTransition(
          sizeFactor: _fadeAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8), // Below AppBar
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                 BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdvisoryScreen()));
              },
              child: _isCompact 
                ? Row(
                    children: [
                       const Icon(Icons.info_outline, color: Colors.white, size: 20),
                       const SizedBox(width: 8),
                       Text(type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                       const SizedBox(width: 8),
                       Expanded(child: Text(message, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis)),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.campaign, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(message, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.7), size: 16),
                    ],
                  ),
            ),
          ),
        );
      },
    );
  }
}
