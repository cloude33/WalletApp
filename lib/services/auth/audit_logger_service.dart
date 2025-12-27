import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/security/security_event.dart';
import 'secure_storage_service.dart';

/// Audit logging service for security events
/// 
/// This service provides comprehensive audit logging capabilities for security events
/// including log rotation, cleanup, and security report generation.
/// It implements secure storage of audit logs with automatic rotation and cleanup
/// to prevent storage overflow while maintaining security compliance.
/// 
/// Features:
/// - Secure audit log storage
/// - Automatic log rotation based on size and time
/// - Log cleanup and retention policies
/// - Security report generation
/// - Event filtering and querying
/// - Export capabilities for compliance
/// 
/// Implements Requirements:
/// - 3.5: Log PIN reset operations
/// - 7.5: Log security setting changes
/// - 9.5: Log suspicious activity
/// - 10.2: Log failed login attempts
/// - 10.3: Log new device access
/// - 10.4: Log security setting changes
class AuditLoggerService {
  static final AuditLoggerService _instance = AuditLoggerService._internal();
  factory AuditLoggerService() => _instance;
  AuditLoggerService._internal();

  // Storage configuration
  static const String _logFilePrefix = 'security_audit_';
  static const String _logFileExtension = '.log';
  static const String _currentLogKey = 'current_audit_log';
  static const String _logIndexKey = 'audit_log_index';
  static const String _logConfigKey = 'audit_log_config';
  
  // Default configuration
  static const int _maxLogFileSize = 1024 * 1024; // 1MB per log file
  static const int _maxLogFiles = 10; // Keep maximum 10 log files
  static const int _maxLogAge = 30; // Keep logs for 30 days
  static const int _maxEventsPerFile = 1000; // Maximum events per file
  
  final AuthSecureStorageService _secureStorage = AuthSecureStorageService();
  bool _isInitialized = false;
  Directory? _logDirectory;
  AuditLogConfig? _config;

  /// Initialize the audit logger service
  /// 
  /// This method sets up the log directory and configuration.
  /// It should be called before using any other methods.
  /// 
  /// Throws [Exception] if initialization fails
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _secureStorage.initialize();
      
      // Get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      _logDirectory = Directory('${appDir.path}/security_logs');
      
      // Create log directory if it doesn't exist
      if (!await _logDirectory!.exists()) {
        await _logDirectory!.create(recursive: true);
      }
      
      // Load or create configuration
      await _loadConfiguration();
      
      // Perform initial cleanup
      await _performCleanup();
      
      _isInitialized = true;
      
      // Log service initialization
      await logSecurityEvent(SecurityEvent(
        type: SecurityEventType.unknown,
        description: 'Audit logger service initialized',
        severity: SecurityEventSeverity.info,
        source: 'AuditLoggerService',
        metadata: {
          'logDirectory': _logDirectory!.path,
          'maxLogFiles': _config!.maxLogFiles,
          'maxLogFileSize': _config!.maxLogFileSize,
        },
      ));
      
    } catch (e) {
      throw Exception('Failed to initialize audit logger service: ${e.toString()}');
    }
  }

  /// Log a security event
  /// 
  /// [event] - The security event to log
  /// 
  /// Returns true if logging was successful, false otherwise
  /// 
  /// Implements all logging requirements (3.5, 7.5, 9.5, 10.2, 10.3, 10.4)
  Future<bool> logSecurityEvent(SecurityEvent event) async {
    try {
      await _ensureInitialized();
      
      // Create log entry
      final logEntry = AuditLogEntry(
        event: event,
        timestamp: DateTime.now(),
        logLevel: _mapSeverityToLogLevel(event.severity),
      );
      
      // Get current log file
      final logFile = await _getCurrentLogFile();
      
      // Check if rotation is needed
      if (await _shouldRotateLog(logFile)) {
        await _rotateLog();
        // Get new current log file after rotation
        final newLogFile = await _getCurrentLogFile();
        return await _writeLogEntry(newLogFile, logEntry);
      } else {
        return await _writeLogEntry(logFile, logEntry);
      }
      
    } catch (e) {
      debugPrint('Failed to log security event: $e');
      return false;
    }
  }

  /// Get security event history
  /// 
  /// [startDate] - Start date for filtering (optional)
  /// [endDate] - End date for filtering (optional)
  /// [eventTypes] - Event types to filter (optional)
  /// [severities] - Severities to filter (optional)
  /// [userId] - User ID to filter (optional)
  /// [limit] - Maximum number of events to return (optional)
  /// 
  /// Returns list of security events matching the criteria
  Future<List<SecurityEvent>> getSecurityHistory({
    DateTime? startDate,
    DateTime? endDate,
    List<SecurityEventType>? eventTypes,
    List<SecurityEventSeverity>? severities,
    String? userId,
    int? limit,
  }) async {
    try {
      await _ensureInitialized();
      
      final events = <SecurityEvent>[];
      final logFiles = await _getLogFiles();
      
      // Sort log files by creation time (newest first)
      logFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      for (final logFile in logFiles) {
        final fileEvents = await _readLogFile(logFile);
        
        for (final event in fileEvents) {
          // Apply filters
          if (startDate != null && event.timestamp.isBefore(startDate)) continue;
          if (endDate != null && event.timestamp.isAfter(endDate)) continue;
          if (eventTypes != null && !eventTypes.contains(event.type)) continue;
          if (severities != null && !severities.contains(event.severity)) continue;
          if (userId != null && event.userId != userId) continue;
          
          events.add(event);
          
          // Check limit
          if (limit != null && events.length >= limit) {
            return events;
          }
        }
      }
      
      return events;
      
    } catch (e) {
      debugPrint('Failed to get security history: $e');
      return [];
    }
  }

  /// Generate security report
  /// 
  /// [startDate] - Start date for the report
  /// [endDate] - End date for the report
  /// [includeDetails] - Whether to include detailed event information
  /// 
  /// Returns a security report containing statistics and events
  Future<SecurityReport> generateSecurityReport({
    DateTime? startDate,
    DateTime? endDate,
    bool includeDetails = true,
  }) async {
    try {
      await _ensureInitialized();
      
      final reportStartDate = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final reportEndDate = endDate ?? DateTime.now();
      
      // Get events for the report period
      final events = await getSecurityHistory(
        startDate: reportStartDate,
        endDate: reportEndDate,
      );
      
      // Generate statistics
      final statistics = _generateStatistics(events);
      
      // Create report
      final report = SecurityReport(
        startDate: reportStartDate,
        endDate: reportEndDate,
        totalEvents: events.length,
        statistics: statistics,
        events: includeDetails ? events : [],
        generatedAt: DateTime.now(),
      );
      
      // Log report generation
      await logSecurityEvent(SecurityEvent(
        type: SecurityEventType.unknown,
        description: 'Security report generated',
        severity: SecurityEventSeverity.info,
        source: 'AuditLoggerService',
        metadata: {
          'reportPeriod': '${reportStartDate.toIso8601String()} - ${reportEndDate.toIso8601String()}',
          'totalEvents': events.length,
        },
      ));
      
      return report;
      
    } catch (e) {
      debugPrint('Failed to generate security report: $e');
      throw Exception('Failed to generate security report: ${e.toString()}');
    }
  }

  /// Export security logs
  /// 
  /// [startDate] - Start date for export (optional)
  /// [endDate] - End date for export (optional)
  /// [format] - Export format ('json' or 'csv')
  /// 
  /// Returns the exported data as a string
  Future<String> exportSecurityLogs({
    DateTime? startDate,
    DateTime? endDate,
    String format = 'json',
  }) async {
    try {
      await _ensureInitialized();
      
      final events = await getSecurityHistory(
        startDate: startDate,
        endDate: endDate,
      );
      
      String exportData;
      
      if (format.toLowerCase() == 'csv') {
        exportData = _exportToCsv(events);
      } else {
        exportData = _exportToJson(events);
      }
      
      // Log export operation
      await logSecurityEvent(SecurityEvent(
        type: SecurityEventType.unknown,
        description: 'Security logs exported',
        severity: SecurityEventSeverity.info,
        source: 'AuditLoggerService',
        metadata: {
          'format': format,
          'eventCount': events.length,
          'exportSize': exportData.length,
        },
      ));
      
      return exportData;
      
    } catch (e) {
      debugPrint('Failed to export security logs: $e');
      throw Exception('Failed to export security logs: ${e.toString()}');
    }
  }

  /// Clear old logs based on retention policy
  /// 
  /// Returns the number of log files removed
  Future<int> clearOldLogs() async {
    try {
      await _ensureInitialized();
      return await _performCleanup();
    } catch (e) {
      debugPrint('Failed to clear old logs: $e');
      return 0;
    }
  }

  /// Get audit log configuration
  /// 
  /// Returns the current audit log configuration
  Future<AuditLogConfig> getConfiguration() async {
    await _ensureInitialized();
    return _config!;
  }

  /// Update audit log configuration
  /// 
  /// [config] - New configuration
  /// 
  /// Returns true if update was successful, false otherwise
  Future<bool> updateConfiguration(AuditLogConfig config) async {
    try {
      await _ensureInitialized();
      
      _config = config;
      
      // Store configuration
      final configJson = json.encode(config.toJson());
      final success = await _secureStorage.write(_logConfigKey, configJson);
      
      if (success) {
        // Log configuration change
        await logSecurityEvent(SecurityEvent(
          type: SecurityEventType.securitySettingsChanged,
          description: 'Audit log configuration updated',
          severity: SecurityEventSeverity.info,
          source: 'AuditLoggerService',
          metadata: config.toJson(),
        ));
        
        // Perform cleanup with new configuration
        await _performCleanup();
      }
      
      return success;
      
    } catch (e) {
      debugPrint('Failed to update configuration: $e');
      return false;
    }
  }

  /// Get log storage statistics
  /// 
  /// Returns statistics about log storage usage
  Future<LogStorageStats> getStorageStats() async {
    try {
      await _ensureInitialized();
      
      final logFiles = await _getLogFiles();
      int totalSize = 0;
      int totalEvents = 0;
      DateTime? oldestLog;
      DateTime? newestLog;
      
      for (final file in logFiles) {
        final stat = await file.stat();
        totalSize += stat.size;
        
        final modified = stat.modified;
        if (oldestLog == null || modified.isBefore(oldestLog)) {
          oldestLog = modified;
        }
        if (newestLog == null || modified.isAfter(newestLog)) {
          newestLog = modified;
        }
        
        // Count events in file (approximate)
        final events = await _readLogFile(file);
        totalEvents += events.length;
      }
      
      return LogStorageStats(
        totalFiles: logFiles.length,
        totalSize: totalSize,
        totalEvents: totalEvents,
        oldestLog: oldestLog,
        newestLog: newestLog,
        averageFileSize: logFiles.isNotEmpty ? totalSize / logFiles.length : 0,
      );
      
    } catch (e) {
      debugPrint('Failed to get storage stats: $e');
      return LogStorageStats(
        totalFiles: 0,
        totalSize: 0,
        totalEvents: 0,
        oldestLog: null,
        newestLog: null,
        averageFileSize: 0,
      );
    }
  }

  // Private helper methods

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Load configuration from storage
  Future<void> _loadConfiguration() async {
    try {
      final configJson = await _secureStorage.read(_logConfigKey);
      if (configJson != null) {
        final configMap = json.decode(configJson as String) as Map<String, dynamic>;
        _config = AuditLogConfig.fromJson(configMap);
      } else {
        // Create default configuration
        _config = AuditLogConfig(
          maxLogFileSize: _maxLogFileSize,
          maxLogFiles: _maxLogFiles,
          maxLogAge: _maxLogAge,
          maxEventsPerFile: _maxEventsPerFile,
        );
        
        // Store default configuration
        final configJson = json.encode(_config!.toJson());
        await _secureStorage.write(_logConfigKey, configJson);
      }
    } catch (e) {
      debugPrint('Failed to load configuration, using defaults: $e');
      _config = AuditLogConfig(
        maxLogFileSize: _maxLogFileSize,
        maxLogFiles: _maxLogFiles,
        maxLogAge: _maxLogAge,
        maxEventsPerFile: _maxEventsPerFile,
      );
    }
  }

  /// Get current log file
  Future<File> _getCurrentLogFile() async {
    final currentLogName = await _secureStorage.read(_currentLogKey) as String?;
    
    if (currentLogName != null) {
      final file = File('${_logDirectory!.path}/$currentLogName');
      if (await file.exists()) {
        return file;
      }
    }
    
    // Create new log file
    return await _createNewLogFile();
  }

  /// Create a new log file
  Future<File> _createNewLogFile() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$_logFilePrefix$timestamp$_logFileExtension';
    final file = File('${_logDirectory!.path}/$fileName');
    
    // Create file with initial metadata
    final metadata = {
      'created': DateTime.now().toIso8601String(),
      'version': '1.0',
      'format': 'json',
    };
    
    await file.writeAsString('${json.encode(metadata)}\n');
    
    // Update current log reference
    await _secureStorage.write(_currentLogKey, fileName);
    
    return file;
  }

  /// Check if log rotation is needed
  Future<bool> _shouldRotateLog(File logFile) async {
    try {
      final stat = await logFile.stat();
      
      // Check file size
      if (stat.size >= _config!.maxLogFileSize) {
        return true;
      }
      
      // Check number of events
      final events = await _readLogFile(logFile);
      if (events.length >= _config!.maxEventsPerFile) {
        return true;
      }
      
      return false;
      
    } catch (e) {
      debugPrint('Error checking log rotation: $e');
      return true; // Rotate on error to be safe
    }
  }

  /// Rotate log files
  Future<void> _rotateLog() async {
    try {
      // Create new log file
      await _createNewLogFile();
      
      // Perform cleanup to remove old files
      await _performCleanup();
      
    } catch (e) {
      debugPrint('Failed to rotate log: $e');
    }
  }

  /// Write log entry to file
  Future<bool> _writeLogEntry(File logFile, AuditLogEntry entry) async {
    try {
      final logLine = '${json.encode(entry.toJson())}\n';
      await logFile.writeAsString(logLine, mode: FileMode.append);
      return true;
    } catch (e) {
      debugPrint('Failed to write log entry: $e');
      return false;
    }
  }

  /// Read log file and parse events
  Future<List<SecurityEvent>> _readLogFile(File logFile) async {
    try {
      final lines = await logFile.readAsLines();
      final events = <SecurityEvent>[];
      
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          
          // Skip metadata lines
          if (json.containsKey('created') && json.containsKey('version')) {
            continue;
          }
          
          // Parse log entry
          final entry = AuditLogEntry.fromJson(json);
          events.add(entry.event);
          
        } catch (e) {
          debugPrint('Failed to parse log line: $line, error: $e');
        }
      }
      
      return events;
      
    } catch (e) {
      debugPrint('Failed to read log file: $e');
      return [];
    }
  }

  /// Get all log files
  Future<List<File>> _getLogFiles() async {
    try {
      final files = await _logDirectory!.list().toList();
      return files
          .whereType<File>()
          .where((file) => file.path.contains(_logFilePrefix))
          .toList();
    } catch (e) {
      debugPrint('Failed to get log files: $e');
      return [];
    }
  }

  /// Perform cleanup of old log files
  Future<int> _performCleanup() async {
    try {
      final logFiles = await _getLogFiles();
      int removedCount = 0;
      
      // Sort by modification time (oldest first)
      logFiles.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
      
      final now = DateTime.now();
      final maxAge = Duration(days: _config!.maxLogAge);
      
      for (final file in logFiles) {
        bool shouldRemove = false;
        
        // Check age
        final age = now.difference(file.lastModifiedSync());
        if (age > maxAge) {
          shouldRemove = true;
        }
        
        // Check count (keep only maxLogFiles)
        if (logFiles.length - removedCount > _config!.maxLogFiles) {
          shouldRemove = true;
        }
        
        if (shouldRemove) {
          try {
            await file.delete();
            removedCount++;
          } catch (e) {
            debugPrint('Failed to delete log file ${file.path}: $e');
          }
        }
      }
      
      return removedCount;
      
    } catch (e) {
      debugPrint('Failed to perform cleanup: $e');
      return 0;
    }
  }

  /// Map security event severity to log level
  LogLevel _mapSeverityToLogLevel(SecurityEventSeverity severity) {
    switch (severity) {
      case SecurityEventSeverity.info:
        return LogLevel.info;
      case SecurityEventSeverity.warning:
        return LogLevel.warning;
      case SecurityEventSeverity.error:
        return LogLevel.error;
      case SecurityEventSeverity.critical:
        return LogLevel.critical;
    }
  }

  /// Generate statistics from events
  Map<String, dynamic> _generateStatistics(List<SecurityEvent> events) {
    final stats = <String, dynamic>{};
    
    // Event type counts
    final typeCounts = <String, int>{};
    final severityCounts = <String, int>{};
    final sourceCounts = <String, int>{};
    final userCounts = <String, int>{};
    
    for (final event in events) {
      // Count by type
      final typeKey = event.type.name;
      typeCounts[typeKey] = (typeCounts[typeKey] ?? 0) + 1;
      
      // Count by severity
      final severityKey = event.severity.name;
      severityCounts[severityKey] = (severityCounts[severityKey] ?? 0) + 1;
      
      // Count by source
      sourceCounts[event.source] = (sourceCounts[event.source] ?? 0) + 1;
      
      // Count by user
      if (event.userId != null) {
        userCounts[event.userId!] = (userCounts[event.userId!] ?? 0) + 1;
      }
    }
    
    stats['eventTypeCounts'] = typeCounts;
    stats['severityCounts'] = severityCounts;
    stats['sourceCounts'] = sourceCounts;
    stats['userCounts'] = userCounts;
    
    // Additional statistics
    stats['totalEvents'] = events.length;
    stats['uniqueUsers'] = userCounts.length;
    stats['criticalEvents'] = severityCounts['critical'] ?? 0;
    stats['errorEvents'] = severityCounts['error'] ?? 0;
    stats['warningEvents'] = severityCounts['warning'] ?? 0;
    stats['infoEvents'] = severityCounts['info'] ?? 0;
    
    return stats;
  }

  /// Export events to JSON format
  String _exportToJson(List<SecurityEvent> events) {
    final exportData = {
      'exportedAt': DateTime.now().toIso8601String(),
      'totalEvents': events.length,
      'events': events.map((e) => e.toJson()).toList(),
    };
    
    return json.encode(exportData);
  }

  /// Export events to CSV format
  String _exportToCsv(List<SecurityEvent> events) {
    final buffer = StringBuffer();
    
    // CSV header
    buffer.writeln('EventID,Type,Timestamp,UserID,Description,Severity,Source,Metadata');
    
    // CSV data
    for (final event in events) {
      final metadata = json.encode(event.metadata).replaceAll('"', '""');
      buffer.writeln(
        '${event.eventId},'
        '${event.type.name},'
        '${event.timestamp.toIso8601String()},'
        '${event.userId ?? ""},'
        '"${event.description.replaceAll('"', '""')}",'
        '${event.severity.name},'
        '${event.source},'
        '"$metadata"'
      );
    }
    
    return buffer.toString();
  }
}

/// Audit log configuration
class AuditLogConfig {
  final int maxLogFileSize;
  final int maxLogFiles;
  final int maxLogAge; // in days
  final int maxEventsPerFile;

  const AuditLogConfig({
    required this.maxLogFileSize,
    required this.maxLogFiles,
    required this.maxLogAge,
    required this.maxEventsPerFile,
  });

  Map<String, dynamic> toJson() {
    return {
      'maxLogFileSize': maxLogFileSize,
      'maxLogFiles': maxLogFiles,
      'maxLogAge': maxLogAge,
      'maxEventsPerFile': maxEventsPerFile,
    };
  }

  factory AuditLogConfig.fromJson(Map<String, dynamic> json) {
    return AuditLogConfig(
      maxLogFileSize: json['maxLogFileSize'] as int? ?? 1024 * 1024,
      maxLogFiles: json['maxLogFiles'] as int? ?? 10,
      maxLogAge: json['maxLogAge'] as int? ?? 30,
      maxEventsPerFile: json['maxEventsPerFile'] as int? ?? 1000,
    );
  }
}

/// Audit log entry
class AuditLogEntry {
  final SecurityEvent event;
  final DateTime timestamp;
  final LogLevel logLevel;

  const AuditLogEntry({
    required this.event,
    required this.timestamp,
    required this.logLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'event': event.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'logLevel': logLevel.name,
    };
  }

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      event: SecurityEvent.fromJson(json['event'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
      logLevel: LogLevel.fromJson(json['logLevel'] as String? ?? 'info'),
    );
  }
}

/// Log level enumeration
enum LogLevel {
  info,
  warning,
  error,
  critical;

  String toJson() => name;
  
  static LogLevel fromJson(String json) {
    return LogLevel.values.firstWhere(
      (level) => level.name == json,
      orElse: () => LogLevel.info,
    );
  }
}

/// Security report
class SecurityReport {
  final DateTime startDate;
  final DateTime endDate;
  final int totalEvents;
  final Map<String, dynamic> statistics;
  final List<SecurityEvent> events;
  final DateTime generatedAt;

  const SecurityReport({
    required this.startDate,
    required this.endDate,
    required this.totalEvents,
    required this.statistics,
    required this.events,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalEvents': totalEvents,
      'statistics': statistics,
      'events': events.map((e) => e.toJson()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory SecurityReport.fromJson(Map<String, dynamic> json) {
    return SecurityReport(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalEvents: json['totalEvents'] as int,
      statistics: json['statistics'] as Map<String, dynamic>,
      events: (json['events'] as List)
          .map((e) => SecurityEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }
}

/// Log storage statistics
class LogStorageStats {
  final int totalFiles;
  final int totalSize;
  final int totalEvents;
  final DateTime? oldestLog;
  final DateTime? newestLog;
  final double averageFileSize;

  const LogStorageStats({
    required this.totalFiles,
    required this.totalSize,
    required this.totalEvents,
    required this.oldestLog,
    required this.newestLog,
    required this.averageFileSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalFiles': totalFiles,
      'totalSize': totalSize,
      'totalEvents': totalEvents,
      'oldestLog': oldestLog?.toIso8601String(),
      'newestLog': newestLog?.toIso8601String(),
      'averageFileSize': averageFileSize,
    };
  }

  factory LogStorageStats.fromJson(Map<String, dynamic> json) {
    return LogStorageStats(
      totalFiles: json['totalFiles'] as int,
      totalSize: json['totalSize'] as int,
      totalEvents: json['totalEvents'] as int,
      oldestLog: json['oldestLog'] != null 
          ? DateTime.parse(json['oldestLog'] as String)
          : null,
      newestLog: json['newestLog'] != null 
          ? DateTime.parse(json['newestLog'] as String)
          : null,
      averageFileSize: (json['averageFileSize'] as num).toDouble(),
    );
  }
}