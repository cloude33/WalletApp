import 'package:flutter/material.dart';
import '../models/kmh_alert_settings.dart';
import '../models/kmh_interest_settings.dart';
import '../services/kmh_alert_service.dart';
import '../services/kmh_interest_settings_service.dart';

class KmhAlertSettingsScreen extends StatefulWidget {
  const KmhAlertSettingsScreen({super.key});

  @override
  State<KmhAlertSettingsScreen> createState() => _KmhAlertSettingsScreenState();
}

class _KmhAlertSettingsScreenState extends State<KmhAlertSettingsScreen> with SingleTickerProviderStateMixin {
  final KmhAlertService _alertService = KmhAlertService();
  final KmhInterestSettingsService _interestSettingsService = KmhInterestSettingsService();
  
  KmhAlertSettings? _alertSettings;
  KmhInterestSettings? _interestSettings;
  bool _isLoading = true;
  bool _hasChanges = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final alertSettings = await _alertService.getAlertSettings();
    final interestSettings = await _interestSettingsService.getSettings();
    setState(() {
      _alertSettings = alertSettings;
      _interestSettings = interestSettings;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_alertSettings != null && _interestSettings != null) {
      await _alertService.updateAlertSettings(_alertSettings!);
      await _interestSettingsService.updateSettings(_interestSettings!);
      
      setState(() {
        _hasChanges = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ayarlar başarıyla kaydedildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _updateAlertSettings(KmhAlertSettings newSettings) {
    setState(() {
      _alertSettings = newSettings;
      _hasChanges = true;
    });
  }

  void _updateInterestSettings(KmhInterestSettings newSettings) {
    setState(() {
      _interestSettings = newSettings;
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
          title: const Text('KMH Ayarları'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Faiz & Vergi'),
              Tab(text: 'Bildirimler'),
            ],
          ),
          actions: [
            if (_hasChanges)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveSettings,
                tooltip: 'Kaydet',
              ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInterestSettingsTab(),
            _buildAlertSettingsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.percent, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'Faiz Oranları (Aylık)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildNumberInput(
                  label: 'Standart KMH Faizi',
                  value: _interestSettings!.standardInterestRate,
                  suffix: '%',
                  onChanged: (val) {
                    _updateInterestSettings(_interestSettings!.copyWith(
                      standardInterestRate: val,
                    ));
                  },
                ),
                const SizedBox(height: 16),
                _buildNumberInput(
                  label: 'Gecikme Faizi',
                  value: _interestSettings!.overdueInterestRate,
                  suffix: '%',
                  onChanged: (val) {
                    _updateInterestSettings(_interestSettings!.copyWith(
                      overdueInterestRate: val,
                    ));
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_outlined, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'Vergi Oranları',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildNumberInput(
                  label: 'KKDF Oranı',
                  value: _interestSettings!.kkdfRate,
                  suffix: '%',
                  onChanged: (val) {
                    _updateInterestSettings(_interestSettings!.copyWith(
                      kkdfRate: val,
                    ));
                  },
                ),
                const SizedBox(height: 16),
                _buildNumberInput(
                  label: 'BSMV Oranı',
                  value: _interestSettings!.bsmvRate,
                  suffix: '%',
                  onChanged: (val) {
                    _updateInterestSettings(_interestSettings!.copyWith(
                      bsmvRate: val,
                    ));
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Card(
          color: Color(0xFFE3F2FD),
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Faiz hesaplaması: (Bakiye * Faiz * Gün) / 3000\nBu tutara vergiler (KKDF + BSMV) eklenir.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberInput({
    required String label,
    required double value,
    required String suffix,
    required Function(double) onChanged,
  }) {
    return TextFormField(
      initialValue: value.toString(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: (text) {
        final val = double.tryParse(text);
        if (val != null) {
          onChanged(val);
        }
      },
    );
  }

  Widget _buildAlertSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildLimitAlertsSection(),
        const SizedBox(height: 24),
        _buildInterestNotificationsSection(),
        const SizedBox(height: 24),
        _buildThresholdsSection(),
      ],
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
              value: _alertSettings!.limitAlertsEnabled,
              onChanged: (value) {
                _updateAlertSettings(_alertSettings!.copyWith(limitAlertsEnabled: value));
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
              value: _alertSettings!.interestNotificationsEnabled,
              onChanged: (value) {
                _updateAlertSettings(_alertSettings!.copyWith(
                  interestNotificationsEnabled: value,
                ));
              },
            ),
            if (_alertSettings!.interestNotificationsEnabled) ...[
              const Divider(),
              ListTile(
                title: const Text('Minimum faiz tutarı'),
                subtitle: Text(
                  'Sadece ₺${_alertSettings!.minimumInterestAmount.toStringAsFixed(2)} '
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
              subtitle: Text('%${_alertSettings!.warningThreshold.toStringAsFixed(0)} kullanımda uyar'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showThresholdDialog(isWarning: true),
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.error, color: Colors.red[700]),
              title: const Text('Kritik eşik'),
              subtitle: Text('%${_alertSettings!.criticalThreshold.toStringAsFixed(0)} kullanımda kritik uyarı'),
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

  Future<void> _showThresholdDialog({required bool isWarning}) async {
    final currentValue = isWarning 
        ? _alertSettings!.warningThreshold 
        : _alertSettings!.criticalThreshold;
    
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
        _updateAlertSettings(_alertSettings!.copyWith(warningThreshold: result));
      } else {
        _updateAlertSettings(_alertSettings!.copyWith(criticalThreshold: result));
      }
    }
  }

  Future<void> _showMinimumInterestDialog() async {
    final controller = TextEditingController(
      text: _alertSettings!.minimumInterestAmount.toStringAsFixed(2),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Minimum Faiz Tutarı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bu tutarın altındaki faizler için bildirim gönderilmez',
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
      _updateAlertSettings(_alertSettings!.copyWith(minimumInterestAmount: result));
    }
  }
}
