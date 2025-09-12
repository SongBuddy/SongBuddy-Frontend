import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _initializeAuth();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    await _authProvider.initialize();
    _authProvider.addListener(_onAuthStateChanged);
    if (mounted) {
      setState(() {});
    }
  }

  void _onAuthStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout from Spotify?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authProvider.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_authProvider.isAuthenticated) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                child: Card(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1DB954).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF1DB954),
                      ),
                    ),
                    title: const Text(
                      'Spotify Account',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(_authProvider.userId ?? 'Connected'),
                    trailing: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout from Spotify'),
                ),
              ),
            ] else ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                child: Card(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_off,
                        color: Colors.orange,
                      ),
                    ),
                    title: const Text(
                      'Not Connected',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Connect your Spotify account'),
                    trailing: const Icon(Icons.warning, color: Colors.orange),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            const Text(
              'App Info',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
