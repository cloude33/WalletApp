import 'package:flutter/material.dart';
import '../utils/background_lock_debug.dart';

class DebugBackgroundLockWidget extends StatefulWidget {
  const DebugBackgroundLockWidget({super.key});

  @override
  State<DebugBackgroundLockWidget> createState() => _DebugBackgroundLockWidgetState();
}

class _DebugBackgroundLockWidgetState extends State<DebugBackgroundLockWidget> {
  Map<String, dynamic> _debugInfo = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    setState(() => _isLoading = true);
    try {
      final info = await BackgroundLockDebug.getDebugInfo();
      setState(() => _debugInfo = info);
    } catch (e) {
      setState(() => _debugInfo = {'error': e.toString()});
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Background Lock Debug',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadDebugInfo,
                ),
              ],
            ),
            const Divider(),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              _buildDebugInfo(),
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugInfo() {
    if (_debugInfo.containsKey('error')) {
      return Text(
        'Error: ${_debugInfo['error']}',
        style: const TextStyle(color: Colors.red),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Authenticated', _debugInfo['isAuthenticated']?.toString() ?? 'Unknown'),
        _buildInfoRow('Background Lock', _debugInfo['backgroundLockEnabled']?.toString() ?? 'Unknown'),
        _buildInfoRow('Background Delay', '${_debugInfo['backgroundLockDelay'] ?? 0}s'),
        _buildInfoRow('Session Timeout', '${_debugInfo['sessionTimeout'] ?? 0}s'),
        _buildInfoRow('Session Active', _debugInfo['sessionActive']?.toString() ?? 'Unknown'),
        _buildInfoRow('Session Remaining', '${_debugInfo['sessionRemainingSeconds'] ?? 0}s'),
        _buildInfoRow('Last Activity', _debugInfo['lastActivityTime'] ?? 'Unknown'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: value.contains('true') ? Colors.green : 
                       value.contains('false') ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await BackgroundLockDebug.debugBackgroundLock();
                  _loadDebugInfo();
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Test Lifecycle'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await BackgroundLockDebug.testInactivityTimeout();
                  _loadDebugInfo();
                },
                icon: const Icon(Icons.timer_off),
                label: const Text('Inactivity Test'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loadDebugInfo,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Info'),
          ),
        ),
      ],
    );
  }
}