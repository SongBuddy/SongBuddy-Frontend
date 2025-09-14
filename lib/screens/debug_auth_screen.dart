import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/auth_service.dart';
import '../services/spotify_service.dart';
import '../providers/auth_provider.dart';

class DebugAuthScreen extends StatefulWidget {
  const DebugAuthScreen({super.key});

  @override
  State<DebugAuthScreen> createState() => _DebugAuthScreenState();
}

class _DebugAuthScreenState extends State<DebugAuthScreen> {
  late final AuthProvider _authProvider;
  late final SpotifyService _spotifyService;
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _spotifyService = SpotifyService();
    _authProvider.addListener(_onAuthStateChanged);
    _authProvider.initialize();
    _runDebugChecks();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    setState(() {});
  }

  Future<void> _runDebugChecks() async {
    final buffer = StringBuffer();
    
    try {
      // Check environment variables
      buffer.writeln('=== Environment Variables ===');
      try {
        final authUrl = _spotifyService.getAuthorizationUrl(state: SpotifyService.generateSecureState());
        buffer.writeln('Environment variables: ✓ Loaded successfully');
      } catch (e) {
        buffer.writeln('Environment variables: ✗ Error - $e');
      }
      buffer.writeln('');

      // Generate auth URL
      buffer.writeln('=== Authorization URL ===');
      final authUrl = _spotifyService.getAuthorizationUrl(state: SpotifyService.generateSecureState());
      buffer.writeln('Generated URL: $authUrl');
      buffer.writeln('');

      // Check URL parsing
      buffer.writeln('=== URL Parsing ===');
      final uri = Uri.parse(authUrl);
      buffer.writeln('Scheme: ${uri.scheme}');
      buffer.writeln('Host: ${uri.host}');
      buffer.writeln('Path: ${uri.path}');
      buffer.writeln('Query parameters: ${uri.queryParameters}');
      buffer.writeln('');

      // Check connectivity
      buffer.writeln('=== Connectivity Check ===');
      try {
        final connectivity = Connectivity();
        final connectivityResult = await connectivity.checkConnectivity();
        final hasInternet = connectivityResult != ConnectivityResult.none;
        buffer.writeln('Internet connection: ${hasInternet ? "✓ Connected" : "✗ No connection"}');
        buffer.writeln('Connection type: $connectivityResult');
      } catch (e) {
        buffer.writeln('Connectivity check failed: $e');
      }
      buffer.writeln('');

      // Check URL launching capability
      buffer.writeln('=== URL Launch Check ===');
      buffer.writeln('Note: URL launch capability will be tested when you click "Test Login"');
      buffer.writeln('Multiple launch modes will be attempted automatically');
      
    } catch (e) {
      buffer.writeln('Error during debug checks: $e');
    }

    setState(() {
      _debugInfo = buffer.toString();
    });
  }

  Future<void> _testLogin() async {
    await _authProvider.login();
  }

  Future<void> _testDeepLink() async {
    // Simulate a deep link callback for testing
    final testUri = Uri.parse('songbuddy://callback?code=test_code&state=test_state');
    await _authProvider.testHandleOAuthCallback(testUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Auth'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auth State
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Authentication State',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('State: ${_authProvider.state}'),
                    if (_authProvider.errorMessage != null)
                      Text('Error: ${_authProvider.errorMessage}'),
                    if (_authProvider.isAuthenticated) ...[
                      Text('User ID: ${_authProvider.userId}'),
                      Text('Access Token: ${_authProvider.accessToken?.substring(0, 20)}...'),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Debug Info
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Debug Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _debugInfo.isEmpty ? 'Running checks...' : _debugInfo,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _runDebugChecks,
                    child: const Text('Refresh Debug Info'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _authProvider.state == AuthState.authenticating ? null : _testLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1DB954),
                      foregroundColor: Colors.white,
                    ),
                    child: _authProvider.state == AuthState.authenticating
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Test Login'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Test Deep Link Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _testDeepLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Test Deep Link (Simulate Callback)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
