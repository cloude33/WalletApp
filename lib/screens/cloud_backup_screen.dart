import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../services/backup_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/auto_backup_service.dart';

class CloudBackupScreen extends StatefulWidget {
  const CloudBackupScreen({super.key});

  @override
  State<CloudBackupScreen> createState() => _CloudBackupScreenState();
}

class _CloudBackupScreenState extends State<CloudBackupScreen> {
  final BackupService _backupService = BackupService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final AutoBackupService _autoBackupService = AutoBackupService();
  List<Map<String, dynamic>> _cloudBackups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCloudBackups();
    _backupService.loadSettings();
  }

  Future<void> _loadCloudBackups() async {
    setState(() => _loading = true);
    
    try {
      final backups = await _backupService.getCloudBackups();
      setState(() {
        _cloudBackups = backups;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulut yedekleri yüklenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulut Yedekleme'),
        backgroundColor: const Color(0xFF5E5CE6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCloudBackups,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleCloudBackup,
        backgroundColor: const Color(0xFF5E5CE6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.cloud_upload),
        label: const Text('Yedekle'),
      ),
    );
  }

  Widget _buildBody() {
    if (FirebaseAuth.instance.currentUser == null) {
      return _buildLoginRequired();
    }

    return Column(
      children: [
        _buildStatusCard(),
        _buildAutoBackupSettings(),
        Expanded(child: _buildBackupsList()),
      ],
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off,
              size: 80,
              color: Color(0xFF8E8E93),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bulut Yedekleme',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verilerinizi bulutta güvenle saklayın ve tüm cihazlarınızda senkronize edin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                // Login ekranına yönlendir
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E5CE6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.login),
              label: const Text('Oturum Aç'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_outlined,
                color: Color(0xFF5E5CE6),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Bulut Durumu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<CloudBackupStatus>(
            valueListenable: _backupService.cloudBackupStatus,
            builder: (context, status, child) {
              return Row(
                children: [
                  _getStatusIcon(status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _backupService.getCloudBackupStatusText(),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<String?>(
            valueListenable: _backupService.lastCloudBackupDate,
            builder: (context, lastBackup, child) {
              return Text(
                lastBackup != null
                    ? 'Son yedekleme: $lastBackup'
                    : 'Henüz yedekleme yapılmamış',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8E8E93),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon(CloudBackupStatus status) {
    switch (status) {
      case CloudBackupStatus.idle:
        return const Icon(Icons.cloud_done, color: Colors.green, size: 20);
      case CloudBackupStatus.error:
        return const Icon(Icons.cloud_off, color: Colors.red, size: 20);
      default:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
    }
  }

  Widget _buildAutoBackupSettings() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: _backupService.autoCloudBackupEnabled,
        builder: (context, autoEnabled, child) {
          return SwitchListTile(
            title: const Text('Otomatik Yedekleme'),
            subtitle: const Text(
              'Verileriniz günlük olarak otomatik buluta yedeklenir',
            ),
            value: autoEnabled,
            onChanged: (value) async {
              _backupService.enableAutoCloudBackup(value);
              await _autoBackupService.enableAutoBackup(value);
            },
            contentPadding: EdgeInsets.zero,
            activeThumbColor: const Color(0xFF5E5CE6),
          );
        },
      ),
    );
  }

  Widget _buildBackupsList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cloudBackups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_queue,
              size: 64,
              color: Color(0xFF8E8E93),
            ),
            SizedBox(height: 16),
            Text(
              'Henüz bulut yedeği yok',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8E8E93),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'İlk yedeğinizi oluşturmak için + butonuna basın',
              style: TextStyle(
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cloudBackups.length,
      itemBuilder: (context, index) {
        final backup = _cloudBackups[index];
        return _buildBackupItem(backup);
      },
    );
  }

  Widget _buildBackupItem(Map<String, dynamic> backup) {
    final uploadedAt = DateTime.parse(backup['uploadedAt']);
    final metadata = backup['metadata'] as Map<String, dynamic>?;
    final deviceInfo = backup['deviceInfo'] as Map<String, dynamic>?;
    final size = backup['size'] as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF5E5CE6),
          child: Icon(
            deviceInfo?['platform'] == 'android' 
                ? Icons.android 
                : Icons.phone_iphone,
            color: Colors.white,
          ),
        ),
        title: Text(
          DateFormat('dd/MM/yyyy HH:mm').format(uploadedAt),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cihaz: ${deviceInfo?['deviceModel'] ?? 'Bilinmeyen'}'),
            Text('Boyut: ${_formatFileSize(size)}'),
            if (metadata != null)
              Text('İşlemler: ${metadata['transactionCount'] ?? 0}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'restore',
              child: const Row(
                children: [
                  Icon(Icons.restore, size: 20),
                  SizedBox(width: 8),
                  Text('Geri Yükle'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: const Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Sil', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'restore') {
              _restoreFromCloudBackup(backup['id']);
            } else if (value == 'delete') {
              _deleteCloudBackup(backup['id']);
            }
          },
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _handleCloudBackup() async {
    try {
      final success = await _backupService.uploadToCloud();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? '✅ Veriler buluta yedeklendi' 
                  : '❌ Bulut yedekleme başarısız',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          _loadCloudBackups();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulut yedekleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restoreFromCloudBackup(String backupId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buluttan Geri Yükle'),
        content: const Text(
          'Mevcut tüm veriler silinecek ve seçilen yedekten geri yüklenecek. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Geri Yükle',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await _backupService.downloadFromCloud();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? '✅ Veriler buluttan geri yüklendi' 
                  : '❌ Bulut geri yükleme başarısız',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulut geri yükleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCloudBackup(String backupId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yedeği Sil'),
        content: const Text(
          'Bu bulut yedeği kalıcı olarak silinecek. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sil',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await _backupService.deleteCloudBackup(backupId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? '✅ Yedek silindi' 
                  : '❌ Yedek silinemedi',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          _loadCloudBackups();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yedek silme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}