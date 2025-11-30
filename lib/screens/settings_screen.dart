import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../models/user.dart';
import '../services/data_service.dart';
import '../services/backup_service.dart';
import '../services/theme_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/app_lock_service.dart';
import 'currency_settings_screen.dart';
import 'user_selection_screen.dart';
import 'debt_list_screen.dart';
import 'categories_screen.dart';
import 'help_screen.dart';
import 'about_screen.dart';
import 'manage_wallets_screen.dart';
import 'notification_settings_screen.dart';
import 'credit_card_list_screen.dart';
import 'recurring_transaction_list_screen.dart';
import '../services/recurring_transaction_service.dart';
import '../repositories/recurring_transaction_repository.dart';
import '../widgets/export_dialog.dart';

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

  // Profile editing state
  bool _isEditingProfile = false;
  bool _isEditingEmail = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _dataService.getCurrentUser();
    final themeMode = await _themeService.getThemeMode();
    setState(() {
      _currentUser = user;
      _currentThemeMode = themeMode;
      _loading = false;

      // Initialize controllers with current user data
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
        content: const Text(
          'Mevcut tüm veriler silinecek ve yedekten geri yüklenecek. Devam etmek istiyor musunuz?',
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

    // Pick backup file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null || result.files.single.path == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final backupFile = File(result.files.single.path!);
      await _backupService.restoreFromBackup(backupFile);

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veriler başarıyla geri yüklendi'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload user data
        await _loadUser();

        // Restart app or navigate to home
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
      backgroundColor: const Color(0xFFF2F2F7),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              'Ayarlar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Profil Resmi Alanı
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
            child: const Text(
              'Profil Resmini Değiştir',
              style: TextStyle(
                color: Color(0xFF00BFA5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        _buildSection('Hesap', [
          _buildEditableSettingItem(
            icon: Icons.person_outline,
            title: 'Profil',
            subtitle: _currentUser?.name ?? 'Kullanıcı',
            isEditing: _isEditingProfile,
            controller: _nameController,
            onSave: _saveProfile,
            onCancel: _cancelProfileEdit,
            onEdit: _startProfileEdit,
          ),
          _buildEditableSettingItem(
            icon: Icons.email_outlined,
            title: 'E-posta',
            subtitle: _currentUser?.email ?? 'Belirtilmemiş',
            isEditing: _isEditingEmail,
            controller: _emailController,
            onSave: _saveEmail,
            onCancel: _cancelEmailEdit,
            onEdit: _startEmailEdit,
          ),
        ]),
        const SizedBox(height: 20),
        _buildSection('Güvenlik', [
          _buildSettingItem(
            icon: Icons.lock_clock,
            title: 'Otomatik Kilit',
            subtitle: 'Uygulama ${AppLockService().getLockTimeout()} dakika sonra kilitlenir',
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF8E8E93),
            ),
            onTap: () async {
              await _showLockTimeoutDialog();
            },
          ),
          _buildSettingItem(
            icon: Icons.fingerprint,
            title: 'Biyometrik Kimlik Doğrulama',
            subtitle: 'Parmak izi ile kilidi aç',
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
        _buildSection('Genel', [
          _buildSettingItem(
            icon: Icons.account_balance_wallet,
            title: 'Cüzdanlarım',
            subtitle: 'Cüzdanlarınızı ve hesaplarınızı yönetin',
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
            icon: Icons.credit_card,
            title: 'Kredi Kartları',
            subtitle: 'Kredi kartlarınızı yönetin',
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF8E8E93),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreditCardListScreen(),
                ),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.account_balance,
            title: 'Kredilerim',
            subtitle: 'Banka kredilerinizi takip edin',
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
            title: 'Tekrarlayan İşlemler',
            subtitle: 'Otomatik işlemlerinizi yönetin',
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
            icon: Icons.category_outlined,
            title: 'Kategoriler',
            subtitle: 'Gelir ve gider kategorilerini yönetin',
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
            icon: Icons.notifications_outlined,
            title: 'Bildirimler',
            subtitle: 'Hatırlatmalar ve uyarılar',
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
            icon: Icons.attach_money,
            title: 'Para Birimi',
            subtitle:
                '${_currentUser?.currencySymbol ?? '₺'} ${_currentUser?.currencyCode ?? 'TRY'}',
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
            icon: Icons.brightness_6,
            title: 'Tema',
            subtitle: _currentThemeMode == ThemeMode.light
                ? 'Açık'
                : _currentThemeMode == ThemeMode.dark
                ? 'Koyu'
                : 'Sistem',
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF8E8E93),
            ),
            onTap: () async {
              await _showThemeDialog();
            },
          ),
        ]),
        const SizedBox(height: 20),
        _buildSection('Veri Yönetimi', [
          _buildSettingItem(
            icon: Icons.file_download_outlined,
            title: 'Export',
            subtitle: 'Verileri dışa aktar',
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF8E8E93),
            ),
            onTap: () async {
              // Show export dialog
              await showDialog(
                context: context,
                builder: (context) => const ExportDialog(),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.backup_outlined,
            title: 'Yedekle',
            subtitle: 'Verilerinizi yedekleyin',
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF8E8E93),
            ),
            onTap: _handleBackup,
          ),
          _buildSettingItem(
            icon: Icons.restore_outlined,
            title: 'Geri Yükle',
            subtitle: 'Yedekten geri yükleyin',
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF8E8E93),
            ),
            onTap: _handleRestore,
          ),
        ]),
        const SizedBox(height: 20),
        _buildSection('Diğer', [
          _buildSettingItem(
            icon: Icons.help_outline,
            title: 'Yardım',
            subtitle: 'SSS ve destek',
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
            title: 'Hakkında',
            subtitle: 'Versiyon 1.0.0',
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
        _buildSection('Hesap', [
          _buildSettingItem(
            icon: Icons.logout,
            title: 'Çıkış Yap',
            subtitle: 'Hesaptan çık',
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: titleColor ?? const Color(0xFF5E5CE6),
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
              color: const Color(0xFFF2F2F7),
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
              color: const Color(0xFFF8F8F8),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
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

  // Profile editing methods
  void _startProfileEdit() {
    setState(() {
      _isEditingProfile = true;
    });
  }

  void _cancelProfileEdit() {
    setState(() {
      _isEditingProfile = false;
      // Reset to original value
      if (_currentUser != null) {
        _nameController.text = _currentUser!.name;
      }
    });
  }

  Future<void> _saveProfile() async {
    print('_saveProfile called with: ${_nameController.text}');
    if (_nameController.text.isNotEmpty && _currentUser != null) {
      final updatedUser = User(
        id: _currentUser!.id,
        name: _nameController.text,
        email: _currentUser!.email,
        avatar: _currentUser!.avatar,
        currencyCode: _currentUser!.currencyCode,
        currencySymbol: _currentUser!.currencySymbol,
      );
      print('Updating user: ${updatedUser.name}');
      await _dataService.updateUser(updatedUser);
      print('User updated successfully');
      setState(() {
        _currentUser = updatedUser;
        _isEditingProfile = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profil güncellendi')));
      }
    } else {
      print(
        'Validation failed: name=${_nameController.text}, user=$_currentUser',
      );
    }
  }

  // Email editing methods
  void _startEmailEdit() {
    setState(() {
      _isEditingEmail = true;
    });
  }

  void _cancelEmailEdit() {
    setState(() {
      _isEditingEmail = false;
      // Reset to original value
      if (_currentUser != null) {
        _emailController.text = _currentUser!.email ?? '';
      }
    });
  }

  Future<void> _saveEmail() async {
    print('_saveEmail called with: ${_emailController.text}');
    if (_currentUser != null) {
      final updatedUser = User(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _emailController.text,
        avatar: _currentUser!.avatar,
        currencyCode: _currentUser!.currencyCode,
        currencySymbol: _currentUser!.currencySymbol,
      );
      print('Updating user email: ${updatedUser.email}');
      await _dataService.updateUser(updatedUser);
      print('Email updated successfully');
      setState(() {
        _currentUser = updatedUser;
        _isEditingEmail = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('E-posta güncellendi')));
      }
    } else {
      print('User is null');
    }
  }

  Future<void> _changeProfilePicture() async {
    print('_changeProfilePicture called');
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      print('Image picked: ${image?.path}');

      if (image != null && _currentUser != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);

        print('Image converted to base64, length: ${base64Image.length}');

        final updatedUser = User(
          id: _currentUser!.id,
          name: _currentUser!.name,
          email: _currentUser!.email,
          avatar: base64Image,
          currencyCode: _currentUser!.currencyCode,
          currencySymbol: _currentUser!.currencySymbol,
        );

        print('Updating user with avatar');
        await _dataService.updateUser(updatedUser);
        print('Avatar updated successfully');

        // Update current user and refresh UI
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
      } else {
        print(
          'Image is null or user is null: image=$image, user=$_currentUser',
        );
      }
    } catch (e) {
      print('Error picking image: $e');
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

  Future<void> _showThemeDialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tema Seçin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Açık Tema'),
                value: ThemeMode.light,
                groupValue: _currentThemeMode,
                activeColor: const Color(0xFF5E5CE6),
                onChanged: (value) async {
                  if (value != null) {
                    await _themeService.setThemeMode(value);
                    setState(() {
                      _currentThemeMode = value;
                    });
                    if (mounted) Navigator.pop(context);
                    // Restart app to apply theme
                    _showRestartSnackbar();
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Koyu Tema'),
                value: ThemeMode.dark,
                groupValue: _currentThemeMode,
                activeColor: const Color(0xFF5E5CE6),
                onChanged: (value) async {
                  if (value != null) {
                    await _themeService.setThemeMode(value);
                    setState(() {
                      _currentThemeMode = value;
                    });
                    if (mounted) Navigator.pop(context);
                    _showRestartSnackbar();
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Sistem Ayarı'),
                value: ThemeMode.system,
                groupValue: _currentThemeMode,
                activeColor: const Color(0xFF5E5CE6),
                onChanged: (value) async {
                  if (value != null) {
                    await _themeService.setThemeMode(value);
                    setState(() {
                      _currentThemeMode = value;
                    });
                    if (mounted) Navigator.pop(context);
                    _showRestartSnackbar();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRestartSnackbar() {
    // Canlı tema değişimi için yeniden başlatmaya gerek yok.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tema değişikliği uygulandı.'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF5E5CE6),
      ),
    );
  }

  Future<void> _showLockTimeoutDialog() async {
    final lockService = AppLockService();
    final currentTimeout = lockService.getLockTimeout();
    int? selectedTimeout = currentTimeout;

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
                        this.setState(() {}); // Refresh the settings screen
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
}
