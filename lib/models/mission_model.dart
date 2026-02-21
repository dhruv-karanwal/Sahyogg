import 'package:cloud_firestore/cloud_firestore.dart';

enum MissionStatus { pending, assigned, in_progress, completed }

class MissionModel {
  final String id;
  final String rescueRequestId;
  final String volunteerId;
  final MissionStatus status;
  final DateTime timestamp;
  final String? citizenMessage;

  MissionModel({
    required this.id,
    required this.rescueRequestId,
    required this.volunteerId,
    required this.status,
    required this.timestamp,
    this.citizenMessage,
  });

  factory MissionModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return MissionModel(
      id: doc.id,
      rescueRequestId: data['rescueRequestId'] ?? '',
      volunteerId: data['volunteerId'] ?? '',
      status: MissionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => MissionStatus.pending,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      citizenMessage: data['citizenMessage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rescueRequestId': rescueRequestId,
      'volunteerId': volunteerId,
      'status': status.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
