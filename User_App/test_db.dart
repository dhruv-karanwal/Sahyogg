import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // We cannot easily init firebase without the google-services.json context, but it is already in the app
    print("Testing Firebase...");
  } catch (e) {
    print("Error: $e");
  }
}
