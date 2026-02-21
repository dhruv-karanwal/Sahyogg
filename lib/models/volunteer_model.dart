import 'package:cloud_firestore/cloud_firestore.dart';

class VolunteerModel {
  final String id;
  final String name;
  final List<String> skills;
  final bool isOnDuty;
  final double rating;
  final int totalMissions;
  final DateTime? dutyStartTime;
  
  // New Operational Fields
  final String phone;
  final String email;
  final String volunteerId;
  final String bloodGroup;
  final String preferredDisasterType;
  final double operationRadius;
  final bool hasVehicle;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final bool isDeadManAlertEnabled;
  final bool isLocationSharingEnabled;

  VolunteerModel({
    required this.id,
    required this.name,
    required this.skills,
    required this.isOnDuty,
    required this.rating,
    required this.totalMissions,
    this.dutyStartTime,
    this.phone = '',
    this.email = '',
    this.volunteerId = '',
    this.bloodGroup = '',
    this.preferredDisasterType = 'Flood',
    this.operationRadius = 10.0,
    this.hasVehicle = false,
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.isDeadManAlertEnabled = false,
    this.isLocationSharingEnabled = true,
  });

  factory VolunteerModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return VolunteerModel(
      id: doc.id,
      name: data['name'] ?? '',
      skills: List<String>.from(data['skills'] ?? []),
      isOnDuty: data['isOnDuty'] ?? false,
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalMissions: data['totalMissions'] ?? 0,
      dutyStartTime: data['dutyStartTime'] != null 
          ? (data['dutyStartTime'] as Timestamp).toDate() 
          : null,
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      volunteerId: data['volunteerId'] ?? 'VOL-${doc.id.substring(0, 4).toUpperCase()}',
      bloodGroup: data['bloodGroup'] ?? 'Unknown',
      preferredDisasterType: data['preferredDisasterType'] ?? 'Flood',
      operationRadius: (data['operationRadius'] ?? 10.0).toDouble(),
      hasVehicle: data['hasVehicle'] ?? false,
      emergencyContactName: data['emergencyContactName'] ?? '',
      emergencyContactPhone: data['emergencyContactPhone'] ?? '',
      isDeadManAlertEnabled: data['isDeadManAlertEnabled'] ?? false,
      isLocationSharingEnabled: data['isLocationSharingEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'skills': skills,
      'isOnDuty': isOnDuty,
      'rating': rating,
      'totalMissions': totalMissions,
      'dutyStartTime': dutyStartTime != null 
          ? Timestamp.fromDate(dutyStartTime!) 
          : null,
      'phone': phone,
      'email': email,
      'volunteerId': volunteerId,
      'bloodGroup': bloodGroup,
      'preferredDisasterType': preferredDisasterType,
      'operationRadius': operationRadius,
      'hasVehicle': hasVehicle,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'isDeadManAlertEnabled': isDeadManAlertEnabled,
      'isLocationSharingEnabled': isLocationSharingEnabled,
    };
  }
}
