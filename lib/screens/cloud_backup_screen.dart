import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../services/backup_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/auto_backup_service.dart';
import 'user_selection_screen.dart';

class CloudBackupScreen extends StatefulWidget {
  const CloudBackupScreen({super.key});

  @override
  State<CloudBackupScreen> createState() => _CloudBackupScreenState();
}

class _CloudBackupScreenState extends State<CloudBackupScreen> {
  final BackupService _backupService = BackupService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final AutoBackupService _autoBackupService = AutoBackupService();

  List<Map<String, dynamic>> _backups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCloudBackups();
  }

  Future<void> _loadCloudBackups() async {
    setState(() => _isLoading = true);
    try {
      final backups = await _backupService.getCloudBackups();
      if (!mounted) return;
      setState(() {
        _backups = backups;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yedekler yüklenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gelişmiş Yedekleme'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCloudBackups,
          ),
        ],
      ),
      body: _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _handleCloudBackup,
        child: const Icon(Icons.cloud_upload),
      ),
    );
  }

  Widget _buildContent() {
    if (FirebaseAuth.instance.currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_circle_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Bulut yedekleme için Google ile giriş yapın',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _handleGoogleSignIn,
              icon: const Icon(Icons.login),
              label: const Text('Google ile Giriş Yap'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildAutoBackupControl(),
        const Divider(),
        _buildStatusHeader(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _backups.isEmpty
                  ? _buildEmptyState()
                  : _buildBackupList(),
        ),
      ],
    );
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Google ile giriş yapılıyor...'),
            ],
          ),
        ),
      );

      final result = await _authService.signInWithGoogle();

      if (!mounted) return;
      Navigator.pop(context);

      if (result != null) {
        setState(() {});
        _loadCloudBackups();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Google ile giriş başarılı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      String errorMessage = 'Google Sign-In başarısız';
      if (e.toString().contains('sign_in_failed')) {
        errorMessage =
            'Google Sign-In hatası. Lütfen:\n'
            '• İnternet bağlantınızı kontrol edin\n'
            '• Google Play Services güncel olduğundan emin olun\n'
            '• Uygulamayı yeniden başlatmayı deneyin';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildStatusHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(Icons.cloud_done, color: Color(0xFF00BFA5)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kayıtlı Yedekler',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Google Drive üzerinde saklanan yedekleriniz',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<CloudBackupStatus>(
            valueListenable: _backupService.cloudBackupStatus,
            builder: (context, status, _) {
              if (status == CloudBackupStatus.uploading ||
                  status == CloudBackupStatus.downloading) {
                return const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAutoBackupControl() {
    return ValueListenableBuilder<bool>(
      valueListenable: _autoBackupService.isAutoBackupEnabledNotifier,
      builder: (context, isEnabled, _) {
        return SwitchListTile(
          title: const Text('Otomatik Yedekleme'),
          subtitle: const Text('Her uygulama açılışında yedekle'),
          value: isEnabled,
          onChanged: (value) => _autoBackupService.setEnabled(value),
          secondary: Icon(
            Icons.sync,
            color: isEnabled ? const Color(0xFF00BFA5) : Colors.grey,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz bulut yedeğiniz yok',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupList() {
    return ListView.builder(
      itemCount: _backups.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final backup = _backups[index];
        return _buildBackupItem(backup);
      },
    );
  }

  Widget _buildBackupItem(Map<String, dynamic> backup) {
    final metadata = backup['metadata'] as Map<String, dynamic>?;
    final date =
        DateTime.tryParse(backup['uploadedAt'] ?? '') ?? DateTime.now();
    final platform = metadata?['platform'] ?? 'Bilinmeyen';
    final device = metadata?['deviceModel'] ?? 'Bilinmeyen Cihaz';
    final version = metadata?['version'] ?? '1.0';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              (platform.toString().toLowerCase() == 'android'
                      ? Colors.green
                      : (platform.toString().toLowerCase() == 'ios'
                          ? Colors.blue
                          : Colors.grey))
                  .withValues(alpha: 0.1),
          child: Icon(
            platform.toString().toLowerCase() == 'android'
                ? Icons.android
                : (platform.toString().toLowerCase() == 'ios'
                    ? Icons.apple
                    : Icons.cloud),
            color: platform.toString().toLowerCase() == 'android'
                ? Colors.green
                : (platform.toString().toLowerCase() == 'ios'
                    ? Colors.blue
                    : Colors.grey),
          ),
        ),
        title: Text(
          DateFormat('dd MMMM yyyy HH:mm', 'tr_TR').format(date.toLocal()),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cihaz: $device'),
            Text('Boyut: ${_formatFileSize(backup['size'] ?? 0)}'),
            Text('Versiyon: $version'),
          ],
        ),
        trailing: _buildBackupActions(backup['id']),
      ),
    );
  }

  Widget _buildBackupActions(String backupId) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'restore') {
          _restoreFromCloudBackup(backupId);
        } else if (value == 'delete') {
          _deleteCloudBackup(backupId);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'restore',
          child: Row(
            children: [
              Icon(Icons.restore, size: 20),
              SizedBox(width: 8),
              Text('Geri Yükle'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('Sil', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleCloudBackup() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await _handleGoogleSignIn();
      if (FirebaseAuth.instance.currentUser == null) return;
    }

    final success = await _backupService.uploadToCloud();
    if (!mounted) return;
    
    final errorMessage = _backupService.lastError.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '✅ Yedekleme başarılı'
              : '❌ Yedekleme başarısız${errorMessage != null ? ': $errorMessage' : ''}',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
    if (success) _loadCloudBackups();
  }

  Future<void> _restoreFromCloudBackup(String backupId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Geri Yükle'),
        content: const Text(
          'Mevcut verileriniz silinecek ve bu yedek yüklenecek. Devam edilsin mi?',
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
      final success = await _backupService.downloadFromCloud(backupId);

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Geri yükleme başarılı. Uygulama yenileniyor...'),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const UserSelectionScreen(),
          ),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Geri yükleme başarısız'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteCloudBackup(String backupId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yedeği Sil'),
        content: const Text(
          'Bu yedek kalıcı olarak silinecek. Onaylıyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await _backupService.deleteCloudBackup(backupId);
      if (!mounted) return;
      
      if (success) _loadCloudBackups();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ Yedek silindi' : '❌ Yedek silinemedi'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
