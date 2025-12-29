import 'package:flutter/material.dart';
import '../models/kmh_alert_settings.dart';
import '../services/kmh_alert_service.dart';
class KmhAlertSettingsScreen extends StatefulWidget {
  const KmhAlertSettingsScreen({super.key});

  @override
  State<KmhAlertSettingsScreen> createState() => _KmhAlertSettingsScreenState();
}

class _KmhAlertSettingsScreenState extends State<KmhAlertSettingsScreen> {
  final KmhAlertService _alertService = KmhAlertService();
  
  KmhAlertSettings? _settings;
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _alertService.getAlertSettings();
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_settings != null) {
      await _alertService.updateAlertSettings(_settings!);
      setState(() {
        _hasChanges = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ayarlar kaydedildi')),
        );
      }
    }
  }

  void _updateSettings(KmhAlertSettings newSettings) {
    setState(() {
      _settings = newSettings;
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        
        if (_hasChanges) {
          final shouldSave = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Değişiklikleri kaydet?'),
              content: const Text('Kaydedilmemiş değişiklikler var. Kaydetmek ister misiniz?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Vazgeç'),
                ),
                TextButton(
                  onPressed: () async {
                    await _saveSettings();
                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            ),
          );
          
          if (shouldSave == true && context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('KMH Bildirim Ayarları'),
          actions: [
            if (_hasChanges)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveSettings,
                tooltip: 'Kaydet',
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildLimitAlertsSection(),
            const SizedBox(height: 24),
            _buildInterestNotificationsSection(),
            const SizedBox(height: 24),
            _buildThresholdsSection(),
            const SizedBox(height: 24),
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitAlertsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Text(
                  'Limit Uyarıları',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'KMH limitinizi ne kadar kullandığınız hakkında bildirim alın',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Limit uyarılarını etkinleştir'),
              subtitle: const Text('Limit kullanımı eşiklere ulaştığında bildirim al'),
              value: _settings!.limitAlertsEnabled,
              onChanged: (value) {
                _updateSettings(_settings!.copyWith(limitAlertsEnabled: value));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestNotificationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Faiz Bildirimleri',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Günlük faiz tahakkuku hakkında bildirim alın',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Faiz bildirimlerini etkinleştir'),
              subtitle: const Text('Günlük faiz tahakkuk ettiğinde bildirim al'),
              value: _settings!.interestNotificationsEnabled,
              onChanged: (value) {
                _updateSettings(_settings!.copyWith(
                  interestNotificationsEnabled: value,
                ));
              },
            ),
            if (_settings!.interestNotificationsEnabled) ...[
              const Divider(),
              ListTile(
                title: const Text('Minimum faiz tutarı'),
                subtitle: Text(
                  'Sadece ₺${_settings!.minimumInterestAmount.toStringAsFixed(2)} '
                  've üzeri faiz için bildirim al',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showMinimumInterestDialog(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Colors.purple[700]),
                const SizedBox(width: 8),
                const Text(
                  'Uyarı Eşikleri',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Bildirim almak istediğiniz kullanım oranlarını ayarlayın',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.warning_amber, color: Colors.orange[400]),
              title: const Text('Uyarı eşiği'),
              subtitle: Text('%${_settings!.warningThreshold.toStringAsFixed(0)} kullanımda uyar'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showThresholdDialog(isWarning: true),
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.error, color: Colors.red[700]),
              title: const Text('Kritik eşik'),
              subtitle: Text('%${_settings!.criticalThreshold.toStringAsFixed(0)} kullanımda kritik uyarı'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showThresholdDialog(isWarning: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Bilgi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '• Limit uyarıları, KMH limitinizin ne kadarını kullandığınızı takip eder\n'
              '• Uyarı eşiği (varsayılan %80): Normal uyarı bildirimi\n'
              '• Kritik eşik (varsayılan %95): Acil uyarı bildirimi\n'
              '• Faiz bildirimleri her gün saat 00:00\'da kontrol edilir\n'
              '• Minimum faiz tutarı altındaki faizler için bildirim gönderilmez',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showThresholdDialog({required bool isWarning}) async {
    final currentValue = isWarning 
        ? _settings!.warningThreshold 
        : _settings!.criticalThreshold;
    
    final controller = TextEditingController(
      text: currentValue.toStringAsFixed(0),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isWarning ? 'Uyarı Eşiği' : 'Kritik Eşik'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isWarning
                  ? 'Limit kullanımı bu yüzdeye ulaştığında uyarı alacaksınız'
                  : 'Limit kullanımı bu yüzdeye ulaştığında kritik uyarı alacaksınız',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Eşik (%)',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value >= 0 && value <= 100) {
                Navigator.pop(context, value);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Geçerli bir yüzde girin (0-100)')),
                );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result != null) {
      if (isWarning) {
        _updateSettings(_settings!.copyWith(warningThreshold: result));
      } else {
        _updateSettings(_settings!.copyWith(criticalThreshold: result));
      }
    }
  }

  Future<void> _showMinimumInterestDialog() async {
    final controller = TextEditingController(
      text: _settings!.minimumInterestAmount.toStringAsFixed(2),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Minimum Faiz Tutarı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bu tutarın altındaki faizler için bildirim gönderilmeyecek',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Minimum tutar',
                prefixText: '₺',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value >= 0) {
                Navigator.pop(context, value);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Geçerli bir tutar girin')),
                );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result != null) {
      _updateSettings(_settings!.copyWith(minimumInterestAmount: result));
    }
  }
}
