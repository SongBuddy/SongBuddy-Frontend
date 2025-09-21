import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/backend_api_service.dart';

class BackendTestScreen extends StatefulWidget {
  const BackendTestScreen({super.key});

  @override
  State<BackendTestScreen> createState() => _BackendTestScreenState();
}

class _BackendTestScreenState extends State<BackendTestScreen> {
  String _status = 'Not tested';
  bool _isLoading = false;
  Map<String, dynamic>? _lastResponse;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing connection...';
    });

    try {
      final response = await BackendApiService.testConnection();
      setState(() {
        _status = '✅ Connection successful!';
        _lastResponse = response;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Connection failed: $e';
        _lastResponse = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testPostConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing POST request...';
    });

    try {
      final response = await BackendApiService.testPostConnection('Hello from Flutter!');
      setState(() {
        _status = '✅ POST request successful!';
        _lastResponse = response;
      });
    } catch (e) {
      setState(() {
        _status = '❌ POST request failed: $e';
        _lastResponse = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getHealthStatus() async {
    setState(() {
      _isLoading = true;
      _status = 'Getting health status...';
    });

    try {
      final response = await BackendApiService.getHealthStatus();
      setState(() {
        _status = '✅ Health check successful!';
        _lastResponse = response;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Health check failed: $e';
        _lastResponse = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Connection Test'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: TextStyle(
                        fontSize: 16,
                        color: _status.contains('✅') ? Colors.green : Colors.red,
                      ),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Buttons
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              child: const Text('Test GET Connection'),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testPostConnection,
              child: const Text('Test POST Connection'),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _getHealthStatus,
              child: const Text('Get Health Status'),
            ),
            
            const SizedBox(height: 16),
            
            // Response Display
            if (_lastResponse != null) ...[
              Text(
                'Last Response:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _prettyJson(_lastResponse!),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _prettyJson(dynamic json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }
}
