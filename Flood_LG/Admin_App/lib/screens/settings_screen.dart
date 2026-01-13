import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/ssh_controller.dart';
import '../controllers/settings_controller.dart';
import '../helpers/debug_helper.dart';
import '../widgets/custom_glass_card.dart';
import '../widgets/custom_input_field.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final SSHController sshController;
  final SettingsController settingsController;

  const SettingsScreen({
    super.key,
    required this.sshController,
    required this.settingsController,
  });

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _rigsNumController;

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: widget.settingsController.lgHost);
    _portController = TextEditingController(text: widget.settingsController.lgPort.toString());
    _usernameController = TextEditingController(text: widget.settingsController.lgUsername);
    _passwordController = TextEditingController(text: widget.settingsController.lgPassword);
    _rigsNumController = TextEditingController(text: widget.settingsController.lgRigsNum.toString());
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _rigsNumController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await widget.sshController.connect(
        host: _hostController.text,
        port: int.parse(_portController.text),
        username: _usernameController.text,
        password: _passwordController.text,
      );

      if (mounted) {
        if (success) {
          _showConnectionDialog(true);
        } else {
          final errorMsg = widget.sshController.lastError ?? 'Connection failed - unknown error';
          _showConnectionDialog(false, errorMsg);
        }
      }
    } catch (e, stackTrace) {
      DebugHelper.error('SETTINGS_SCREEN', 'Test connection failed', e, stackTrace);
      if (mounted) {
        _showConnectionDialog(false, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showConnectionDialog(bool success, [String? error]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error_outline, 
              color: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
            const SizedBox(width: 12),
            Text(
              success ? 'Connected!' : 'Failed',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          success 
              ? 'Successfully connected to Liquid Galaxy master.' 
              : 'Could not connect: $error',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.settingsController.saveSettings(
        host: _hostController.text,
        port: int.parse(_portController.text),
        username: _usernameController.text,
        password: _passwordController.text,
        rigsNum: int.parse(_rigsNumController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Settings saved!', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Configuration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomGlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.dns, color: Color(0xFF3B82F6)),
                            const SizedBox(width: 12),
                            Text(
                              'Master Node Connection',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        CustomInputField(
                          controller: _hostController,
                          label: 'IP Address',
                          icon: Icons.computer,
                          validator: (value) => 
                            (value == null || value.isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomInputField(
                          controller: _portController,
                          label: 'SSH Port',
                          icon: Icons.settings_ethernet,
                          keyboardType: TextInputType.number,
                          validator: (value) => 
                            (value == null || value.isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomInputField(
                          controller: _usernameController,
                          label: 'Username',
                          icon: Icons.person,
                          validator: (value) => 
                            (value == null || value.isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomInputField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock,
                          obscureText: _obscurePassword,
                          validator: (value) => 
                            (value == null || value.isEmpty) ? 'Required' : null,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white54,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 16),
                         CustomInputField(
                          controller: _rigsNumController,
                          label: 'Number of Rigs',
                          icon: Icons.monitor,
                          keyboardType: TextInputType.number,
                          validator: (value) => 
                            (value == null || value.isEmpty) ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _isLoading ? null : _testConnection,
                          icon: _isLoading 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                            : const Icon(Icons.wifi_find),
                          label: const Text('Test Connection'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF3B82F6),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveSettings,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Configuration'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981), // Green
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
      ),
    );
  }
}
