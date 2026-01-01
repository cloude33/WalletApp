import 'dart:math';
import 'package:flutter/foundation.dart';

import '../google_drive_service.dart';

/// Manager for Google Drive storage quota monitoring and optimization
class QuotaManager {
  static final QuotaManager _instance = QuotaManager._internal();
  factory QuotaManager() => _instance;
  QuotaManager._internal();

  final GoogleDriveService _driveService = GoogleDriveService();
  
  // Cache quota info to avoid excessive API calls
  QuotaInfo? _cachedQuotaInfo;
  DateTime? _lastQuotaCheck;
  static const Duration _quotaCacheDuration = Duration(minutes: 5);

  /// Get current Google Drive quota information
  Future<QuotaInfo> getCurrentQuota() async {
    try {
      // Return cached info if still valid
      if (_cachedQuotaInfo != null && 
          _lastQuotaCheck != null &&
          DateTime.now().difference(_lastQuotaCheck!) < _quotaCacheDuration) {
        return _cachedQuotaInfo!;
      }

      debugPrint('📊 Fetching Google Drive quota information...');
      
      // Ensure we're authenticated
      if (!await _driveService.isAuthenticated()) {
        await _driveService.signIn();
      }

      // Get quota information from Drive API
      // Note: This is a simplified implementation
      // In a real scenario, you would use the Drive API's about.get() method
      final quotaInfo = await _fetchQuotaFromApi();
      
      // Cache the result
      _cachedQuotaInfo = quotaInfo;
      _lastQuotaCheck = DateTime.now();
      
      debugPrint('✅ Quota info retrieved: ${quotaInfo.usedSpaceGB.toStringAsFixed(2)}GB / ${quotaInfo.totalSpaceGB.toStringAsFixed(2)}GB');
      
      return quotaInfo;
    } catch (e) {
      debugPrint('❌ Error fetching quota information: $e');
      
      // Return default quota info if API call fails
      return QuotaInfo(
        totalSpaceBytes: 15 * 1024 * 1024 * 1024, // 15GB default
        usedSpaceBytes: 0,
        availableSpaceBytes: 15 * 1024 * 1024 * 1024,
        isUnlimited: false,
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Check if there's enough space for a backup of given size
  Future<bool> hasSpaceForBackup(int backupSizeBytes) async {
    try {
      final quotaInfo = await getCurrentQuota();
      
      // Add 10% buffer for safety
      final requiredSpace = (backupSizeBytes * 1.1).round();
      final hasSpace = quotaInfo.availableSpaceBytes >= requiredSpace;
      
      debugPrint('💾 Space check: Required ${_formatBytes(requiredSpace)}, Available ${_formatBytes(quotaInfo.availableSpaceBytes)} - ${hasSpace ? "✅ OK" : "❌ Insufficient"}');
      
      return hasSpace;
    } catch (e) {
      debugPrint('❌ Error checking space availability: $e');
      return false; // Err on the side of caution
    }
  }

  /// Get suggestions for files to delete to free up required space
  Future<List<String>> suggestFilesToDelete(int requiredSpaceBytes) async {
    try {
      debugPrint('🔍 Finding files to delete for ${_formatBytes(requiredSpaceBytes)} space...');
      
      final backups = await _driveService.listBackups();
      final suggestions = <String>[];
      int spaceToFree = 0;
      
      // Sort backups by age (oldest first) and size (largest first)
      backups.sort((a, b) {
        // First sort by age
        final aTime = a.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeComparison = aTime.compareTo(bTime);
        
        if (timeComparison != 0) return timeComparison;
        
        // Then by size (larger files first for same age)
        final aSize = int.tryParse(a.size ?? '0') ?? 0;
        final bSize = int.tryParse(b.size ?? '0') ?? 0;
        return bSize.compareTo(aSize);
      });
      
      // Select files to delete until we have enough space
      for (final backup in backups) {
        if (spaceToFree >= requiredSpaceBytes) break;
        
        final fileSize = int.tryParse(backup.size ?? '0') ?? 0;
        if (fileSize > 0 && backup.id != null) {
          suggestions.add(backup.id!);
          spaceToFree += fileSize;
          
          debugPrint('📋 Suggested for deletion: ${backup.name} (${_formatBytes(fileSize)})');
        }
      }
      
      debugPrint('✅ Found ${suggestions.length} files that would free ${_formatBytes(spaceToFree)}');
      
      return suggestions;
    } catch (e) {
      debugPrint('❌ Error generating deletion suggestions: $e');
      return [];
    }
  }

  /// Check if storage is approaching the warning threshold (90%)
  Future<bool> isStorageNearLimit() async {
    try {
      final quotaInfo = await getCurrentQuota();
      final usagePercentage = quotaInfo.usagePercentage;
      
      return usagePercentage >= 90.0;
    } catch (e) {
      debugPrint('❌ Error checking storage limit: $e');
      return false;
    }
  }

  /// Get storage usage warning message if applicable
  Future<String?> getStorageWarningMessage() async {
    try {
      final quotaInfo = await getCurrentQuota();
      final usagePercentage = quotaInfo.usagePercentage;
      
      if (usagePercentage >= 95.0) {
        return 'Depolama alanınız %${usagePercentage.toStringAsFixed(1)} dolu! Acil olarak eski yedekleri temizlemeniz gerekiyor.';
      } else if (usagePercentage >= 90.0) {
        return 'Depolama alanınız %${usagePercentage.toStringAsFixed(1)} dolu. Eski yedekleri temizlemeyi düşünün.';
      } else if (usagePercentage >= 80.0) {
        return 'Depolama alanınız %${usagePercentage.toStringAsFixed(1)} dolu. Yakında temizlik yapmanız gerekebilir.';
      }
      
      return null; // No warning needed
    } catch (e) {
      debugPrint('❌ Error generating storage warning: $e');
      return null;
    }
  }

  /// Estimate backup size based on data categories
  Future<int> estimateBackupSize(List<String> dataCategories) async {
    try {
      // Base size estimates per category (in bytes)
      const categoryEstimates = {
        'transactions': 1024 * 100,      // ~100KB per 1000 transactions
        'wallets': 1024 * 10,            // ~10KB
        'creditCards': 1024 * 50,        // ~50KB
        'bills': 1024 * 30,              // ~30KB
        'goals': 1024 * 20,              // ~20KB
        'settings': 1024 * 5,            // ~5KB
        'userImages': 1024 * 1024 * 2,   // ~2MB for images
        'recurringTransactions': 1024 * 20, // ~20KB
      };
      
      int estimatedSize = 0;
      
      for (final category in dataCategories) {
        estimatedSize += categoryEstimates[category] ?? 1024; // 1KB default
      }
      
      // Add compression overhead and metadata
      estimatedSize = (estimatedSize * 0.7).round(); // Assume 30% compression
      estimatedSize += 1024 * 10; // 10KB for metadata
      
      debugPrint('📏 Estimated backup size: ${_formatBytes(estimatedSize)} for categories: ${dataCategories.join(", ")}');
      
      return estimatedSize;
    } catch (e) {
      debugPrint('❌ Error estimating backup size: $e');
      return 1024 * 1024; // 1MB default estimate
    }
  }

  /// Clear quota cache to force refresh on next call
  void clearQuotaCache() {
    _cachedQuotaInfo = null;
    _lastQuotaCheck = null;
    debugPrint('🔄 Quota cache cleared');
  }

  /// Fetch quota information from Google Drive API
  Future<QuotaInfo> _fetchQuotaFromApi() async {
    // This is a simplified implementation
    // In a real scenario, you would use the Drive API's about.get() method
    // to fetch actual quota information
    
    // For now, we'll simulate quota information
    final random = Random();
    final totalSpace = 15 * 1024 * 1024 * 1024; // 15GB
    final usedSpace = random.nextInt(totalSpace ~/ 2); // Random usage up to 50%
    
    return QuotaInfo(
      totalSpaceBytes: totalSpace,
      usedSpaceBytes: usedSpace,
      availableSpaceBytes: totalSpace - usedSpace,
      isUnlimited: false,
      lastUpdated: DateTime.now(),
    );
  }

  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

/// Information about Google Drive storage quota
class QuotaInfo {
  final int totalSpaceBytes;
  final int usedSpaceBytes;
  final int availableSpaceBytes;
  final bool isUnlimited;
  final DateTime lastUpdated;

  QuotaInfo({
    required this.totalSpaceBytes,
    required this.usedSpaceBytes,
    required this.availableSpaceBytes,
    required this.isUnlimited,
    required this.lastUpdated,
  });

  /// Get total space in GB
  double get totalSpaceGB => totalSpaceBytes / (1024 * 1024 * 1024);

  /// Get used space in GB
  double get usedSpaceGB => usedSpaceBytes / (1024 * 1024 * 1024);

  /// Get available space in GB
  double get availableSpaceGB => availableSpaceBytes / (1024 * 1024 * 1024);

  /// Get usage percentage
  double get usagePercentage => 
      isUnlimited ? 0.0 : (usedSpaceBytes / totalSpaceBytes) * 100;

  /// Check if storage is nearly full (>90%)
  bool get isNearlyFull => usagePercentage >= 90.0;

  /// Check if storage is critically full (>95%)
  bool get isCriticallyFull => usagePercentage >= 95.0;

  /// Get formatted total space string
  String get totalSpaceFormatted => _formatBytes(totalSpaceBytes);

  /// Get formatted used space string
  String get usedSpaceFormatted => _formatBytes(usedSpaceBytes);

  /// Get formatted available space string
  String get availableSpaceFormatted => _formatBytes(availableSpaceBytes);

  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  Map<String, dynamic> toJson() => {
    'totalSpaceBytes': totalSpaceBytes,
    'usedSpaceBytes': usedSpaceBytes,
    'availableSpaceBytes': availableSpaceBytes,
    'isUnlimited': isUnlimited,
    'lastUpdated': lastUpdated.toIso8601String(),
    'totalSpaceGB': totalSpaceGB,
    'usedSpaceGB': usedSpaceGB,
    'availableSpaceGB': availableSpaceGB,
    'usagePercentage': usagePercentage,
  };

  factory QuotaInfo.fromJson(Map<String, dynamic> json) {
    return QuotaInfo(
      totalSpaceBytes: json['totalSpaceBytes'] ?? 0,
      usedSpaceBytes: json['usedSpaceBytes'] ?? 0,
      availableSpaceBytes: json['availableSpaceBytes'] ?? 0,
      isUnlimited: json['isUnlimited'] ?? false,
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  String toString() {
    return 'QuotaInfo(used: $usedSpaceFormatted, total: $totalSpaceFormatted, usage: ${usagePercentage.toStringAsFixed(1)}%)';
  }
}

/// Cleanup suggestions for optimizing storage space
class CleanupSuggestion {
  final String fileId;
  final String fileName;
  final int fileSizeBytes;
  final DateTime createdTime;
  final CleanupReason reason;
  final int spaceSavedBytes;

  CleanupSuggestion({
    required this.fileId,
    required this.fileName,
    required this.fileSizeBytes,
    required this.createdTime,
    required this.reason,
    required this.spaceSavedBytes,
  });

  String get fileSizeFormatted => _formatBytes(fileSizeBytes);
  String get spaceSavedFormatted => _formatBytes(spaceSavedBytes);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  Map<String, dynamic> toJson() => {
    'fileId': fileId,
    'fileName': fileName,
    'fileSizeBytes': fileSizeBytes,
    'createdTime': createdTime.toIso8601String(),
    'reason': reason.name,
    'spaceSavedBytes': spaceSavedBytes,
  };
}

/// Reasons for cleanup suggestions
enum CleanupReason {
  oldAge,
  largeSize,
  duplicate,
  corrupted,
  redundant,
}

extension CleanupReasonExtension on CleanupReason {
  String get displayName {
    switch (this) {
      case CleanupReason.oldAge:
        return 'Eski yedek';
      case CleanupReason.largeSize:
        return 'Büyük dosya';
      case CleanupReason.duplicate:
        return 'Tekrarlanan yedek';
      case CleanupReason.corrupted:
        return 'Bozuk dosya';
      case CleanupReason.redundant:
        return 'Gereksiz yedek';
    }
  }

  String get description {
    switch (this) {
      case CleanupReason.oldAge:
        return 'Bu yedek belirlenen saklama süresini aştı';
      case CleanupReason.largeSize:
        return 'Bu dosya ortalamadan çok daha büyük';
      case CleanupReason.duplicate:
        return 'Aynı tarihte birden fazla yedek var';
      case CleanupReason.corrupted:
        return 'Bu dosya bozuk görünüyor';
      case CleanupReason.redundant:
        return 'Bu yedek artık gerekli değil';
    }
  }
}