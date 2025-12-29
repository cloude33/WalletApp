import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/app_icons.dart';

class IconShowcaseScreen extends StatelessWidget {
  const IconShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Renkli İkonlar'),
        backgroundColor: const Color(0xFF5E5CE6),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Finansal İkonlar',
              [
                _buildIconItem('Para', AppIcons.money, Colors.green),
                _buildIconItem('Cüzdan', AppIcons.wallet, Colors.blue),
                _buildIconItem('Kredi Kartı', AppIcons.creditCard, Colors.purple),
                _buildIconItem('Banka', AppIcons.bank, Colors.indigo),
                _buildIconItem('Madeni Para', AppIcons.coins, Colors.orange),
                _buildIconItem('Kumbara', AppIcons.piggyBank, Colors.pink),
                _buildIconItem('Gelir', AppIcons.income, Colors.green),
                _buildIconItem('Gider', AppIcons.expense, Colors.red),
                _buildIconItem('Transfer', AppIcons.transfer, Colors.blue),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Kategori İkonları',
              [
                _buildIconItem('Yemek', AppIcons.food, Colors.orange),
                _buildIconItem('Kahve', AppIcons.coffee, Colors.brown),
                _buildIconItem('Araba', AppIcons.car, Colors.blue),
                _buildIconItem('Alışveriş', AppIcons.shopping, Colors.purple),
                _buildIconItem('Sağlık', AppIcons.health, Colors.red),
                _buildIconItem('Eğlence', AppIcons.entertainment, Colors.pink),
                _buildIconItem('Ev', AppIcons.home, Colors.green),
                _buildIconItem('Uçak', AppIcons.plane, Colors.cyan),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Fatura İkonları',
              [
                _buildIconItem('Elektrik', AppIcons.electricity, Colors.yellow.shade700),
                _buildIconItem('Su', AppIcons.water, Colors.blue.shade600),
                _buildIconItem('Doğalgaz', AppIcons.gas, Colors.orange.shade700),
                _buildIconItem('İnternet', AppIcons.internet, Colors.indigo),
                _buildIconItem('Telefon', AppIcons.phone, Colors.teal),
                _buildIconItem('Kira', AppIcons.rent, Colors.brown),
                _buildIconItem('Sigorta', AppIcons.insurance, Colors.cyan),
                _buildIconItem('Abonelik', AppIcons.subscription, Colors.deepPurple),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Uygulama İkonları',
              [
                _buildIconItem('Dashboard', AppIcons.dashboard, Colors.blue),
                _buildIconItem('İstatistik', AppIcons.statistics, Colors.green),
                _buildIconItem('Takvim', AppIcons.calendar, Colors.red),
                _buildIconItem('Ayarlar', AppIcons.settings, Colors.grey),
                _buildIconItem('Profil', AppIcons.profile, Colors.indigo),
                _buildIconItem('Bildirim', AppIcons.notification, Colors.orange),
                _buildIconItem('Yedekleme', AppIcons.backup, Colors.blue),
                _buildIconItem('Güvenlik', AppIcons.shield, Colors.green),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Renkli Kategori İkonları (Helper Methods)',
              [
                AppIcons.getCategoryIcon('yemek', size: 32),
                AppIcons.getCategoryIcon('ulaşım', size: 32),
                AppIcons.getCategoryIcon('alışveriş', size: 32),
                AppIcons.getCategoryIcon('sağlık', size: 32),
                AppIcons.getCategoryIcon('eğlence', size: 32),
                AppIcons.getCategoryIcon('ev', size: 32),
                AppIcons.getCategoryIcon('elektrik', size: 32),
                AppIcons.getCategoryIcon('su', size: 32),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Finansal Durum İkonları',
              [
                AppIcons.getFinancialStatusIcon('gelir', size: 32),
                AppIcons.getFinancialStatusIcon('gider', size: 32),
                AppIcons.getFinancialStatusIcon('transfer', size: 32),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Yedekleme Durumu İkonları',
              [
                AppIcons.getBackupStatusIcon('başarılı', size: 32),
                AppIcons.getBackupStatusIcon('hata', size: 32),
                AppIcons.getBackupStatusIcon('uyarı', size: 32),
                AppIcons.getBackupStatusIcon('yükleniyor', size: 32),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Güvenlik İkonları',
              [
                AppIcons.getSecurityIcon('kilitli', size: 32),
                AppIcons.getSecurityIcon('açık', size: 32),
                AppIcons.getSecurityIcon('biyometrik', size: 32),
                AppIcons.getSecurityIcon('güvenli', size: 32),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> icons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: icons,
        ),
      ],
    );
  }

  Widget _buildIconItem(String label, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: FaIcon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}