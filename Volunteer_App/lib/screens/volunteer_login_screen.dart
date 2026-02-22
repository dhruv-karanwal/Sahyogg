import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'volunteer_registration_screen.dart';
import '../main.dart'; // For MainNavigation route
import 'package:provider/provider.dart';
import '../services/volunteer_repository.dart';

class VolunteerLoginScreen extends StatefulWidget {
  const VolunteerLoginScreen({super.key});

  @override
  State<VolunteerLoginScreen> createState() => _VolunteerLoginScreenState();
}

class _VolunteerLoginScreenState extends State<VolunteerLoginScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Give it a small fake delay to feel like a real auth flow
    await Future.delayed(const Duration(milliseconds: 1200));

    final repo = Provider.of<VolunteerRepository>(context, listen: false);
    
    // In a real app we would query 'volunteers' where 'phone' == phone snippet here.
    // Since the system is demo-wired to 'vol_001', we check if that mock exists.
    final bool exists = await repo.hasProfile('vol_001');

    if (mounted) {
      setState(() => _isLoading = false);
      if (exists) {
        // Successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      } else {
        // No profile found, redirect to registration
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile not found. Please register first.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VolunteerRegistrationScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              // Logo/Icon
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6C9EEB).withOpacity(0.1),
                ),
                child: const Icon(Icons.volunteer_activism, size: 60, color: Color(0xFF6C9EEB)),
              ),
              const SizedBox(height: 48),
              
              Text(
                'Welcome Back',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your phone number to login to your Sahyog Volunteer Portal.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 48),

              // Login Input Field
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.phone_android, color: Colors.blueGrey),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                ),
              ),
              const SizedBox(height: 32),

              // Login Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C9EEB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : Text(
                        'LOGIN',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                ),
              ),
              const SizedBox(height: 24),

              // Registration Redirect
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VolunteerRegistrationScreen()),
                      );
                    },
                    child: Text(
                      'Register',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF6C9EEB),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
