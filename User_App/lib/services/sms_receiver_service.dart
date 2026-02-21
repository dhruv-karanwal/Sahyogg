import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart';

@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) async {
  print("Background SMS Received in User App: ${message.body}");
  await UserSMSReceiverService.processIncomingAdvisory(message);
}

class UserSMSReceiverService {
  static final Telephony telephony = Telephony.instance;
  static bool _isListening = false;

  static Future<void> startListening() async {
    if (_isListening) return;

    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted != null && permissionsGranted) {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) async {
          print("Foreground SMS Received in User App: ${message.body}");
          await processIncomingAdvisory(message);
        },
        onBackgroundMessage: backgroundMessageHandler,
      );
      _isListening = true;
      print('User SMS Receiver is now actively listening for offline broadcast alerts.');
    }
  }

  static Future<void> processIncomingAdvisory(SmsMessage message) async {
    final body = message.body?.trim() ?? '';
    
    // Check if it's our admin broadcast
    if (!body.startsWith('FLOOD_ALERT:')) return;

    try {
      final parts = body.split('\n');
      final header = parts[0];
      final type = header.replaceAll('FLOOD_ALERT:', '').trim();
      final msg = parts.length > 1 ? parts.sublist(1).join('\n') : '';

      final advisory = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': type.isEmpty ? 'Alert' : type,
        'message': msg,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'source': 'OFFLINE_SMS',
      };

      final prefs = await SharedPreferences.getInstance();
      final List<String> cached = prefs.getStringList('offline_advisories') ?? [];
      cached.insert(0, jsonEncode(advisory)); // newest first
      await prefs.setStringList('offline_advisories', cached);
      
      print('Saved Offline Advisory to SharedPreferences.');
    } catch (e) {
      print('Error parsing offline advisory: $e');
    }
  }
}
