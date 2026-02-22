import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:telephony/telephony.dart';
import '../firebase_options.dart';

/// Top-level background message handler for the telephony plugin.
/// Must be outside of any class.
@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  print("Background SMS Received: ${message.body}");
  await SMSReceiverService.processIncomingSOS(message);
}

class SMSReceiverService {
  static final Telephony telephony = Telephony.instance;
  static bool _isListening = false;

  /// Starts listening to incoming SMS messages.
  static Future<void> startListening() async {
    if (_isListening) return;

    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted != null && permissionsGranted) {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) async {
          print("Foreground SMS Received: ${message.body}");
          await processIncomingSOS(message);
        },
        onBackgroundMessage: backgroundMessageHandler,
      );
      _isListening = true;
      print('SMS Receiver Service is now actively listening for offline SOS requests.');
    } else {
      print('Failed to start SMS Receiver: Permissions not granted.');
    }
  }

  /// Parses the SMS and pushes it to Firestore if it's a valid offline SOS request.
  static Future<void> processIncomingSOS(SmsMessage message) async {
    final body = message.body?.trim() ?? '';
    final sender = message.address ?? 'Unknown';

    // Format expected from User App: 
    // "SOS EMERGENCY\nType: [EmergencyType]\nPeople: [Count]\nPhone: [UserPhone]\nDesc: [Description]"
    
    if (!body.startsWith('SOS EMERGENCY')) {
      print('Ignoring SMS: Not an SOS request.');
      return;
    }

    // Log the raw SMS explicitly to provide a Live Feed for the Admin Dashboard
    try {
      await FirebaseFirestore.instance
          .collection('Disasters')
          .doc('Flood')
          .collection('incoming_sms')
          .add({
        'sender': sender,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Raw SMS logged to incoming_sms feed.');
    } catch (e) {
      print('Error logging raw SMS feed: $e');
    }

    try {
      print('Valid SOS EMERGENCY SMS matched. Parsing payload...');
      
      // Parse fields using regex or string splitting
      String type = _extractField(body, 'Type:');
      String countStr = _extractField(body, 'People:');
      String phone = _extractField(body, 'Phone:');
      String desc = _extractField(body, 'Desc:');

      int peopleCount = int.tryParse(countStr) ?? 1;
      
      // Fallback phone if the body didn't contain it
      if (phone.isEmpty) phone = sender;
      
      final db = FirebaseFirestore.instance;
      
      final newDoc = {
        'description': desc,
        'peopleCount': peopleCount,
        'emergencyType': type,
        'phone': phone,
        // Since it's offline SMS, we don't have accurate GPS natively via just standard SMS text
        'lat': 0.0,
        'lng': 0.0,
        'district': 'Unknown (SMS Offline)',
        'city': 'Unknown',
        'area': 'SMS Intercept', 
        'priority': 'MEDIUM', // System will flag this for manual triage or a backend cloud function could run NLP triage on insert
        'triageTag': 'Awaiting Triage',
        'status': 'PENDING',
        'source': 'OFFLINE_SMS',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final batch = db.batch();
      final newDocRef = db.collection('Disasters').doc('Flood').collection('rescue_requests').doc();
      
      batch.set(newDocRef, newDoc);

      // Increment counters in the global area summary for accurate analytics syncing
      final summaryRef = db.doc('Disasters/Flood/rescue_summary/${newDoc['district']}/cities/${newDoc['city']}/areas/${newDoc['area']}');
      
      batch.set(
          summaryRef,
          {
            'district': newDoc['district'],
            'city': newDoc['city'],
            'area': newDoc['area'],
            'lat': 0.0,
            'lng': 0.0,
            'totalSOS': FieldValue.increment(1),
            'pending': FieldValue.increment(1),
            'lastUpdated': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));

      await batch.commit();
      print('Offline SMS successfully injected into Firebase & Synced with Analytics!');
      
    } catch (e) {
      print('Error parsing or pushing offline SOS: $e');
    }
  }

  /// Helper to extract a value from the SMS body format.
  static String _extractField(String body, String fieldName) {
    try {
      final lines = body.split('\n');
      for (final line in lines) {
        if (line.startsWith(fieldName)) {
          return line.substring(fieldName.length).trim();
        }
      }
    } catch (e) {
     return '';
    }
    return '';
  }
}
