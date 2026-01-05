// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import '../models/user.dart';
import '../services/data_service.dart';
import '../services/backup_service.dart';
import '../services/theme_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/app_lock_service.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';
import 'currency_settings_screen.dart';
import 'user_selection_screen.dart';
import 'debt_list_screen.dart';
import 'bill_templates_screen.dart';
import 'categories_screen.dart';
import 'help_screen.dart';
import 'about_screen.dart';
import 'manage_wallets_screen.dart';
import 'notification_settings_screen.dart';
import 'recurring_transaction_list_screen.dart';
import 'change_password_screen.dart';
import 'cloud_backup_screen.dart';

import '../services/recurring_transaction_service.dart';
import '../repositories/recurring_transaction_repository.dart';
import '../widgets/export_dialog.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/debug_background_lock_widget.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DataService _dataService = DataService();
  final BackupService _backupService = BackupService();
  final ThemeService _themeService = ThemeService();
  final NotificationService _notificationService = NotificationService();
  User? _currentUser;
  bool _loading = true;
  ThemeMode _currentThemeMode = ThemeMode.system;
  bool _isEditingProfile = false;
  bool _isEditingEmail = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isBiometricAvailable = false;
  String? _authMethod;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _checkBiometricAvailability();
    _loadAuthMethod();
  }

  Future<void> _loadAuthMethod() async {
    final method = await AuthService().getCurrentAuthMethod();
    if (mounted) {
      setState(() {
        _authMethod = method;
      });
    }
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await AuthService().isBiometricAvailable();
    if (mounted) {
      setState(() {
        _isBiometricAvailable = available;
      });
    }
  }

  Future<void> _loadUser() async {
    final user = await _dataService.getCurrentUser();
    final themeMode = await _themeService.getThemeMode();
    setState(() {
      _currentUser = user;
      _currentThemeMode = themeMode;
      _loading = false;
      if (user != null) {
        _nameController.text = user.name;
        _emailController.text = user.email ?? '';
      }
    });
  }

  Future<void> _handleBackup() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await _backupService.shareBackup();

    if (mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Yedek başarıyla oluşturuldu' : 'Yedekleme başarısız',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleRestore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Geri Yükle'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mevcut tüm veriler silinecek ve yedekten geri yüklenecek. Devam etmek istiyor musunuz?',
            ),
            SizedBox(height: 16),
            Text(
              '📱 Platform Desteği:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '✅ Android yedekleri iPhone\'a yüklenebilir',
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
            Text(
              '✅ iPhone yedekleri Android\'e yüklenebilir',
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
            SizedBox(height: 8),
            Text(
              'Yedek dosyası (.mbk) formatında olmalıdır.',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mbk', 'zip'],
    );

    if (result == null || result.files.single.path == null) return;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final backupFile = File(result.files.single.path!);
      
      // Metadata kontrol et
      final metadata = await _backupService.getBackupMetadata(backupFile);
      
      if (metadata != null && mounted) {
        final platformInfo = metadata.isAndroidBackup
            ? '🤖 Android'
            : metadata.isIOSBackup
            ? '🍎 iOS'
            : '❓ Bilinmeyen';
            
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Yedek Bilgisi'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Platform: $platformInfo'),
                Text('Cihaz: ${metadata.deviceModel}'),
                Text('Tarih: ${DateFormat('dd/MM/yyyy HH:mm').format(metadata.createdAt)}'),
                const SizedBox(height: 8),
                Text('İşlemler: ${metadata.transactionCount}'),
                Text('Cüzdanlar: ${metadata.walletCount}'),
                const SizedBox(height: 12),
                if (metadata.isAndroidBackup && Platform.isIOS)
                  const Text(
                    '✅ Android yedeği iPhone\'a yüklenecek',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  )
                else if (metadata.isIOSBackup && Platform.isAndroid)
                  const Text(
                    '✅ iOS yedeği Android\'e yüklenecek',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Devam Et'),
              ),
            ],
          ),
        );
        
        if (shouldContinue != true) return;
      }
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      await _backupService.restoreFromBackup(backupFile);

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veriler başarıyla geri yüklendi'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadUser();
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const UserSelectionScreen(),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Geri yükleme başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildSettings(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.settings,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ),
          const ThemeToggleButton(),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: GestureDetector(
            onTap: _changeProfilePicture,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF00BFA5),
                  backgroundImage: _currentUser?.avatar != null
                      ? MemoryImage(base64Decode(_currentUser!.avatar!))
                      : null,
                  child: _currentUser?.avatar == null
                      ? Text(
                          _currentUser?.name[0].toUpperCase() ?? 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00BFA5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: _changeProfilePicture,
            child: Text(
              AppLocalizations.of(context)!.profile, // Profil Resmini Değiştir yerine Profil kullanalım veya arb ekleyip
              style: const TextStyle(
                color: Color(0xFF00BFA5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        _buildSection(AppLocalizations.of(context)!.accountSection, [
          _buildEditableSettingItem(
            icon: Icons.person_outline,
            title: AppLocalizations.of(context)!.profile,
            subtitle: _currentUser?.name ?? AppLocalizations.of(context)!.userDefault,
            isEditing: _isEditingProfile,
            controller: _nameController,
            onSave: _saveProfile,
            onCancel: _cancelProfileEdit,
            onEdit: _startProfileEdit,
          ),
          _buildEditableSettingItem(
            icon: Icons.email_outlined,
            title: AppLocalizations.of(context)!.email,
            subtitle: _currentUser?.email ?? AppLocalizations.of(context)!.notSpecified,
            isEditing: _isEditingEmail,
            controller: _emailController,
            onSave: _saveEmail,
            onCancel: _cancelEmailEdit,
            onEdit: _startEmailEdit,
          ),
          if (_authMethod == null)
            _buildSettingItem(
              icon: Icons.lock_outline,
              title: AppLocalizations.of(context)!.changePassword,
              subtitle: AppLocalizations.of(context)!.updatePasswordDesc,
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF8E8E93),
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
        ]),
        const SizedBox(height: 20),
        _buildSection(AppLocalizations.of(context)!.generalSection, [
          _buildSettingItem(
            icon: Icons.account_balance_wallet,
            title: AppLocalizations.of(context)!.myWallets,
            subtitle: AppLocalizations.of(context)!.manageWalletsDesc,
            iconColor: Colors.blue,
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF8E8E93),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageWalletsScreen(),
                ),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.receipt_long,
            title: AppLocalizations.of(context)!.myBills,
            subtitle: AppLocalizations.of(context)!.manageBillsDesc,
            iconColor: Colors.orange,
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF8E8E93),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BillTemplatesScreen(),
                ),
              );
              _loadUser();
            },
          ),
          _buildSettingItem(
            icon: Icons.category_outlined,
            title: AppLocalizations.of(context)!.categories,
            subtitle: AppLocalizations.of(context)!.manageCategoriesDesc,
            iconColor: Colors.purple,
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF8E8E93),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoriesScreen(),
                ),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.account_balance,
            title: AppLocalizations.of(context)!.debts,
            subtitle: AppLocalizations.of(context)!.trackDebtsDesc,
            iconColor: Colors.red,
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF8E8E93),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DebtListScreen()),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.repeat,
            title: AppLocalizations.of(context)!.recurringTransactions,
            subtitle: AppLocalizations.of(context)!.manageRecurringDesc,
            iconColor: Colors.teal,
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF8E8E93),
            ),
            onTap: () async {
              final repository = RecurringTransactionRepository();
              await repository.init();

              final service = RecurringTransactionService(
                repository,
                _dataService,
                _notificationService,
              );

              if (!mounted) return;

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      RecurringTransactionListScreen(service: service),
                ),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.notifications_outlined,
            title: AppLocalizations.of(context)!.notifications,
            subtitle: AppLocalizations.of(context)!.notificationsDesc,
            iconColor: Colors.orange,
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF8E8E93),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.currency_exchange,
            title: AppLocalizations.of(context)!.currency,
            subtitle:
                '${_currentUser?.currencySymbol ?? '₺'} ${_currentUser?.currencyCode ?? 'TRY'}',
            iconColor: Colors.green,
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF8E8E93),
            ),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CurrencySettingsScreen(),
                ),
              );
              if (result == true) {
                _loadUser();
              }
            },
          ),
          _buildSettingItem(
            icon: Icons.language,
            title: AppLocalizations.of(context)!.language,
            subtitle: Localizations.localeOf(context).languageCode == 'tr' 
                ? 'Türkçe' 
                : 'English',
            iconColor: Colors.teal,
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF8E8E93),
            ),
            onTap: () async {
              await _showLanguageDialog();
              setState(() {});
            },
          ),
        ]),
        const SizedBox(height: 20),
        _buildSection(AppLocalizations.of(context)!.dataSection, [
          _buildSettingItem(
            icon: Icons.cloud_outlined,
            title: AppLocalizations.of(context)!.cloudBackup,
            subtitle: AppLocalizations.of(context)!.cloudBackupDesc,
            iconColor: Colors.blueAccent,
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF8E8E93),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CloudBackupScreen(),
                ),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.backup_outlined,
            title: AppLocalizations.of(context)!.backup,
            subtitle: AppLocalizations.of(context)!.backupDesc,
            iconColor: Colors.blue,
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF8E8E93),
            ),
            onTap: _handleBackup,
          ),
          _buildSettingItem(
            icon: Icons.restore_outlined,
            title: AppLocalizations.of(context)!.restore,
            subtitle: AppLocalizations.of(context)!.restoreDesc,
            iconColor: Colors.green,
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF8E8E93),
            ),
            onTap: _handleRestore,
          ),
          _buildSettingItem(
            icon: Icons.file_download_outlined,
            title: AppLocalizations.of(context)!.export,
            subtitle: AppLocalizations.of(context)!.exportDesc,
            iconColor: Colors.indigo,
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF8E8E93),
            ),
            onTap: () async {
              await showDialog(
                context: context,
                builder: (context) => const ExportDialog(),
              );
            },
          ),
        ]),
        const SizedBox(height: 20),
        _buildSection(AppLocalizations.of(context)!.securitySection, [
          _buildSettingItem(
            icon: Icons.lock_clock,
            title: AppLocalizations.of(context)!.autoLock,
            subtitle:
                '${AppLocalizations.of(context)!.autoLock} ${AppLockService().getLockTimeout()} dk',
            iconColor: Colors.red,
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF8E8E93),
            ),
            onTap: () async {
              await _showLockTimeoutDialog();
            },
          ),
          if (_isBiometricAvailable)
            _buildSettingItem(
              icon: Icons.fingerprint,
              title: AppLocalizations.of(context)!.biometricAuth,
              subtitle: AppLocalizations.of(context)!.biometricDesc,
              iconColor: Colors.blue,
              trailing: FutureBuilder<bool>(
                future: AuthService().isBiometricEnabled(),
                builder: (context, snapshot) {
                  final isEnabled = snapshot.data ?? false;
                  return Switch(
                    value: isEnabled,
                    onChanged: (value) async {
                      await AuthService().setBiometricEnabled(value);
                      setState(() {});
                    },
                  );
                },
              ),
            ),
        ]),
        const SizedBox(height: 20),
        _buildSection(AppLocalizations.of(context)!.otherSection, [
          _buildSettingItem(
            icon: Icons.help_outline,
            title: AppLocalizations.of(context)!.help,
            subtitle: AppLocalizations.of(context)!.faqDesc,
            iconColor: Colors.cyan,
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF8E8E93),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.info_outline,
            title: AppLocalizations.of(context)!.about,
            subtitle: 'Versiyon 1.0.0',
            iconColor: Colors.blueGrey,
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF8E8E93),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
        ]),
        const SizedBox(height: 20),
        _buildSection(AppLocalizations.of(context)!.accountSection, [
          _buildSettingItem(
            icon: Icons.logout,
            title: AppLocalizations.of(context)!.logout,
            subtitle: AppLocalizations.of(context)!.logoutDesc,
            titleColor: const Color(0xFFFF3B30),
            onTap: () async {
              await Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserSelectionScreen(),
                ),
              );
            },
          ),
        ]),
        const SizedBox(height: 20),
        _buildSection(AppLocalizations.of(context)!.dangerZone, [
          _buildSettingItem(
            icon: Icons.delete_forever,
            title: AppLocalizations.of(context)!.resetApp,
            subtitle: AppLocalizations.of(context)!.resetAppDesc,
            titleColor: const Color(0xFFFF3B30),
            onTap: _resetApp,
          ),
        ]),
        const SizedBox(height: 20),
        // Debug widget (sadece debug modda göster)
        if (kDebugMode) ...[
          _buildSection('DEBUG', [
            const DebugBackgroundLockWidget(),
          ]),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? titleColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final effectiveIconColor = iconColor ?? titleColor ?? const Color(0xFF5E5CE6);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: effectiveIconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: effectiveIconColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: titleColor ?? const Color(0xFF1C1C1E),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildEditableSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEditing,
    required TextEditingController controller,
    required VoidCallback onSave,
    required VoidCallback onCancel,
    required VoidCallback onEdit,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF5E5CE6), size: 24),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1C1E),
            ),
          ),
          subtitle: isEditing
              ? null
              : Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E8E93),
                  ),
                ),
          trailing: isEditing
              ? null
              : IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF5E5CE6)),
                  onPressed: onEdit,
                ),
          onTap: isEditing ? null : onEdit,
        ),
        if (isEditing)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF8F8F8),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF3A3A3C)
                      : Colors.grey.shade200,
                ),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: onCancel, child: const Text('İptal')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5E5CE6),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Kaydet'),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
  void _startProfileEdit() {
    setState(() {
      _isEditingProfile = true;
    });
  }

  void _cancelProfileEdit() {
    setState(() {
      _isEditingProfile = false;
      if (_currentUser != null) {
        _nameController.text = _currentUser!.name;
      }
    });
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isNotEmpty && _currentUser != null) {
      final updatedUser = User(
        id: _currentUser!.id,
        name: _nameController.text,
        email: _currentUser!.email,
        avatar: _currentUser!.avatar,
        currencyCode: _currentUser!.currencyCode,
        currencySymbol: _currentUser!.currencySymbol,
      );
      await _dataService.updateUser(updatedUser);
      setState(() {
        _currentUser = updatedUser;
        _isEditingProfile = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profil güncellendi')));
      }
    }
  }
  void _startEmailEdit() {
    setState(() {
      _isEditingEmail = true;
    });
  }

  void _cancelEmailEdit() {
    setState(() {
      _isEditingEmail = false;
      if (_currentUser != null) {
        _emailController.text = _currentUser!.email ?? '';
      }
    });
  }

  Future<void> _saveEmail() async {
    if (_currentUser != null) {
      final updatedUser = User(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _emailController.text,
        avatar: _currentUser!.avatar,
        currencyCode: _currentUser!.currencyCode,
        currencySymbol: _currentUser!.currencySymbol,
      );
      await _dataService.updateUser(updatedUser);
      setState(() {
        _currentUser = updatedUser;
        _isEditingEmail = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('E-posta güncellendi')));
      }
    }
  }

  Future<void> _changeProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null && _currentUser != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);

        final updatedUser = User(
          id: _currentUser!.id,
          name: _currentUser!.name,
          email: _currentUser!.email,
          avatar: base64Image,
          currencyCode: _currentUser!.currencyCode,
          currencySymbol: _currentUser!.currencySymbol,
        );

        await _dataService.updateUser(updatedUser);
        setState(() {
          _currentUser = updatedUser;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil resmi güncellendi'),
              backgroundColor: Color(0xFF00BFA5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Resim seçilemedi')));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _showLockTimeoutDialog() async {
    final lockService = AppLockService();
    int? selectedTimeout = lockService.getLockTimeout();

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Otomatik Kilit Süresi'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<int>(
                    title: const Text('1 Dakika'),
                    value: 1,
                    groupValue: selectedTimeout,
                    activeColor: const Color(0xFF5E5CE6),
                    onChanged: (value) {
                      setState(() => selectedTimeout = value);
                    },
                  ),
                  RadioListTile<int>(
                    title: const Text('5 Dakika'),
                    value: 5,
                    groupValue: selectedTimeout,
                    activeColor: const Color(0xFF5E5CE6),
                    onChanged: (value) {
                      setState(() => selectedTimeout = value);
                    },
                  ),
                  RadioListTile<int>(
                    title: const Text('10 Dakika'),
                    value: 10,
                    groupValue: selectedTimeout,
                    activeColor: const Color(0xFF5E5CE6),
                    onChanged: (value) {
                      setState(() => selectedTimeout = value);
                    },
                  ),
                  RadioListTile<int>(
                    title: const Text('30 Dakika'),
                    value: 30,
                    groupValue: selectedTimeout,
                    activeColor: const Color(0xFF5E5CE6),
                    onChanged: (value) {
                      setState(() => selectedTimeout = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedTimeout != null) {
                      await lockService.setLockTimeout(selectedTimeout!);
                      if (mounted) {
                        Navigator.pop(context);
                        this.setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Kilit süresi güncellendi'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _resetApp() async {
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Uyarı'),
        content: const Text(
          'Uygulamayı sıfırlamak üzeresiniz. Bu işlem:\n\n'
          '• Tüm kullanıcıları\n'
          '• Tüm cüzdanları\n'
          '• Tüm işlemleri\n'
          '• Tüm kredi kartlarını\n'
          '• Tüm borçları\n'
          '• Tüm ayarları\n\n'
          'kalıcı olarak silecektir. Bu işlem geri alınamaz!\n\n'
          'Devam etmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Devam Et',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );

    if (firstConfirm != true) return;

    if (!mounted) return;
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFF3B30),
        title: const Text(
          '🚨 Son Uyarı',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Bu işlem GERİ ALINAMAZ!\n\n'
          'Tüm verileriniz kalıcı olarak silinecek.\n\n'
          'Yedek almadıysanız, verilerinizi geri getiremezsiniz.\n\n'
          'Uygulamayı sıfırlamak istediğinizden kesinlikle emin misiniz?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(backgroundColor: Colors.white),
            child: const Text(
              'Evet, Sıfırla',
              style: TextStyle(
                color: Color(0xFFFF3B30),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (secondConfirm != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _dataService.clearAllData();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uygulama başarıyla sıfırlandı'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const UserSelectionScreen(),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sıfırlama başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showLanguageDialog() async {
    final languageService = LanguageService();
    
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  AppLocalizations.of(context)!.selectLanguage,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Text('🇹🇷', style: TextStyle(fontSize: 24)),
                title: const Text('Türkçe'),
                trailing: languageService.locale.languageCode == 'tr'
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () async {
                  await languageService.setLocale(const Locale('tr'));
                  if (mounted) Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                title: const Text('English'),
                trailing: languageService.locale.languageCode == 'en'
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () async {
                  await languageService.setLocale(const Locale('en'));
                  if (mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
