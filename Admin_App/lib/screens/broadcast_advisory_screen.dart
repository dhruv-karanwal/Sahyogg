import 'package:flutter/material.dart';

class BroadcastAdvisoryScreen extends StatefulWidget {
  const BroadcastAdvisoryScreen({super.key});

  @override
  State<BroadcastAdvisoryScreen> createState() => _BroadcastAdvisoryScreenState();
}

class _BroadcastAdvisoryScreenState extends State<BroadcastAdvisoryScreen> {
  final _messageController = TextEditingController();
  final int _charLimit = 140;
  bool _isSending = false;
  bool _isActive = false;
  String? _lastPostedMessage;
  String _selectedAdvisoryType = 'Information';
  
  final List<String> _advisoryTypes = ['Information', 'Warning', 'Evacuation', 'All Clear'];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndSend() async {
    if (_messageController.text.isEmpty) return;

    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Confirm Broadcast', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: $_selectedAdvisoryType', style: const TextStyle(color: Colors.amber)),
            const SizedBox(height: 8),
            Text('Message: "${_messageController.text}"', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            const Text('This will be sent immediately to all citizens.', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.black),
            child: const Text('Confirm Broadcast'),
          ),
        ],
      ),
    );

    if (shouldSend == true) {
      _sendAdvisory();
    }
  }

  Future<void> _sendAdvisory() async {
    if (_messageController.text.isEmpty) return;

    setState(() => _isSending = true);
    
    // Simulate Firestore write
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _lastPostedMessage = _messageController.text;
      _isActive = true;
      _isSending = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Advisory Broadcasted: "${_limitText(_lastPostedMessage!, 30)}..."'),
          backgroundColor: Colors.amber.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context); // Optional: stay on screen or pop? User req says "Entry Point" tile, so pop is fine or stay. 
      // Prompt says "On Send... Immediately sync to User app", doesn't explicitly say close.
      // But usually "Send buttons" might keep you there or close. I'll just clear input or update status.
      // Actually, staying and showing "Active Advisory" status is better.
      _messageController.clear();
    }
  }

  Future<void> _clearAdvisory() async {
    setState(() => _isSending = true);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _isActive = false;
      _lastPostedMessage = null;
      _isSending = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Advisory Cleared'),
          backgroundColor: Colors.grey,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _limitText(String text, int limit) {
    if (text.length <= limit) return text;
    return text.substring(0, limit);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Broadcast Advisory'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          color: theme.scaffoldBackgroundColor,
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              theme.colorScheme.surface,
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 48, color: Colors.amber.shade500),
                      const SizedBox(height: 16),
                      Text(
                        'Emergency Advisory',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.amber.shade500,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Broadcast urgent messages to all citizen apps immediately.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Active Advisory Status Card
                if (_isActive && _lastPostedMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.podcasts, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Text('LIVE BROADCAST • $_selectedAdvisoryType'.toUpperCase(), style: TextStyle(color: Colors.amber.shade400, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _lastPostedMessage!,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],

                // New Advisory Input Section
                Text('New Message', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
                const SizedBox(height: 12),
                
                // Advisory Type Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedAdvisoryType,
                  dropdownColor: const Color(0xFF1E1E1E),
                   decoration: InputDecoration(
                    labelText: 'Advisory Type', // Added Label
                    prefixIcon: const Icon(Icons.category, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05), // Matches input field
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), // Matches input field
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.amber.shade500)),
                   ),
                  items: _advisoryTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (v) => setState(() => _selectedAdvisoryType = v!),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _messageController,
                  maxLength: _charLimit,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter advisory message (e.g., "Heavy rain alert in Aluva. Move to higher ground.")',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.amber.shade500),
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton(
                            onPressed: _isSending || !_isActive ? null : _clearAdvisory,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: _isActive ? Colors.red.shade400 : Colors.grey.withOpacity(0.2)),
                              foregroundColor: Colors.red.shade400,
                            ),
                            child: Text(_isSending ? '...' : 'Clear Active Advisory'),
                          ),
                           if (_isActive)
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Removes the current advisory from citizen applications.',
                                style: TextStyle(color: Colors.white38, fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isSending ? null : _confirmAndSend,
                        icon: const Icon(Icons.send),
                        label: Text(_isSending ? 'Broadcasting...' : 'Broadcast Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
