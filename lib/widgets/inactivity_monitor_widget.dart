import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth/session_manager.dart';
import '../services/auth/auth_service.dart';

class InactivityMonitorWidget extends StatefulWidget {
  const InactivityMonitorWidget({super.key});

  @override
  State<InactivityMonitorWidget> createState() => _InactivityMonitorWidgetState();
}

class _InactivityMonitorWidgetState extends State<InactivityMonitorWidget> {
  final SessionManager _sessionManager = SessionManager();
  final AuthService _authService = AuthService();
  
  Timer? _updateTimer;
  Duration? _sessionRemaining;
  Duration? _timeSinceLastActivity;
  bool _isSessionActive = false;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startMonitoring() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateStatus();
    });
    _updateStatus();
  }

  Future<void> _updateStatus() async {
    try {
      final sessionRemaining = await _sessionManager.getSessionRemainingTime();
      final sessionActive = await _sessionManager.isSessionActive();
      final authenticated = await _authService.isAuthenticated();
      
      final lastActivity = _sessionManager.lastActivityTime;
      final timeSinceActivity = DateTime.now().difference(lastActivity);

      if (mounted) {
        setState(() {
          _sessionRemaining = sessionRemaining;
          _timeSinceLastActivity = timeSinceActivity;
          _isSessionActive = sessionActive;
          _isAuthenticated = authenticated;
        });
      }
    } catch (e) {
      debugPrint('Inactivity monitor update error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        border: Border.all(color: _getStatusColor()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _getStatusIcon(),
                color: _getStatusColor(),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Session Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStatusInfo(),
        ],
      ),
    );
  }

  Widget _buildStatusInfo() {
    return Column(
      children: [
        _buildInfoRow(
          'Session Active',
          _isSessionActive ? 'Yes' : 'No',
          _isSessionActive ? Colors.green : Colors.red,
        ),
        _buildInfoRow(
          'Time Since Activity',
          _formatDuration(_timeSinceLastActivity),
          _getActivityColor(),
        ),
        _buildInfoRow(
          'Session Remaining',
          _formatDuration(_sessionRemaining),
          _getTimeRemainingColor(),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (!_isSessionActive) return Colors.red;
    if ((_sessionRemaining?.inSeconds ?? 0) < 60) return Colors.orange;
    return Colors.green;
  }

  IconData _getStatusIcon() {
    if (!_isSessionActive) return Icons.lock;
    if ((_sessionRemaining?.inSeconds ?? 0) < 60) return Icons.warning;
    return Icons.check_circle;
  }

  Color _getActivityColor() {
    final seconds = _timeSinceLastActivity?.inSeconds ?? 0;
    if (seconds < 30) return Colors.green;
    if (seconds < 120) return Colors.orange;
    return Colors.red;
  }

  Color _getTimeRemainingColor() {
    final seconds = _sessionRemaining?.inSeconds ?? 0;
    if (seconds > 120) return Colors.green;
    if (seconds > 30) return Colors.orange;
    return Colors.red;
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'N/A';
    
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}