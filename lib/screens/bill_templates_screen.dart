import 'package:flutter/material.dart';
import '../utils/format_helper.dart';
import '../models/bill_template.dart';
import '../services/bill_template_service.dart';
import 'add_bill_template_screen.dart';
import 'bill_template_detail_screen.dart';
class BillTemplatesScreen extends StatefulWidget {
  const BillTemplatesScreen({super.key});

  @override
  State<BillTemplatesScreen> createState() => _BillTemplatesScreenState();
}

class _BillTemplatesScreenState extends State<BillTemplatesScreen> {
  final BillTemplateService _service = BillTemplateService();
  List<BillTemplate> _templates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _loading = true);
    final templates = await _service.getTemplates();
    setState(() {
      _templates = templates;
      _loading = false;
    });
  }

  IconData _getCategoryIcon(BillTemplateCategory category) {
    switch (category) {
      case BillTemplateCategory.electricity:
        return Icons.bolt;
      case BillTemplateCategory.water:
        return Icons.water_drop;
      case BillTemplateCategory.gas:
        return Icons.local_fire_department;
      case BillTemplateCategory.internet:
        return Icons.wifi;
      case BillTemplateCategory.phone:
        return Icons.phone;
      case BillTemplateCategory.rent:
        return Icons.home;
      case BillTemplateCategory.insurance:
        return Icons.shield;
      case BillTemplateCategory.subscription:
        return Icons.subscriptions;
      case BillTemplateCategory.other:
        return Icons.receipt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faturalarım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddBillTemplateScreen(),
                ),
              );
              if (result == true) {
                _loadTemplates();
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadTemplates,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _templates.length,
                itemBuilder: (context, index) {
                  final template = _templates[index];
                  return _buildTemplateCard(template);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Henüz fatura tanımlamadınız',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Elektrik, su, doğalgaz gibi\nfaturalarınızı buradan tanımlayın',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddBillTemplateScreen(),
                ),
              );
              if (result == true) {
                _loadTemplates();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('İlk Faturanı Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(BillTemplate template) {
    // Alt başlık bilgisini belirle (Numara veya Abone No)
    String? detailText;
    if (template.category == BillTemplateCategory.phone) {
      if (template.phoneNumber != null) {
        detailText = FormatHelper.formatPhoneNumber(template.phoneNumber);
      }
    } else {
      // Abone numarası varsa onu öncelikli göster, yoksa sağlayıcı ismini kontrol et
      if (template.accountNumber != null &&
          template.accountNumber!.isNotEmpty) {
        detailText = 'No: ${template.accountNumber}';
      } else if (template.provider != null &&
          template.provider != template.displayTitle) {
        detailText = template.provider;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getCategoryIcon(template.category),
            color: const Color(0xFF00BFA5),
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                template.displayTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            if (!template.isActive)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: Text(
                  'PASİF',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (detailText != null)
                Text(
                  detailText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              Text(
                template.categoryDisplayName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  BillTemplateDetailScreen(template: template),
            ),
          );
          if (result == true) {
            _loadTemplates();
          }
        },
      ),
    );
  }
}
