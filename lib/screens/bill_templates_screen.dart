import 'package:flutter/material.dart';
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(template.category),
            color: const Color(0xFF00BFA5),
          ),
        ),
        title: Text(
          template.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (template.category == BillTemplateCategory.phone &&
                template.phoneNumber != null)
              Text(
                template.phoneNumber!.startsWith('0')
                    ? template.phoneNumber!
                    : '0${template.phoneNumber!}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (template.category != BillTemplateCategory.phone &&
                template.provider != null)
              Text(template.provider!),
            Text(
              template.categoryDisplayName,
              style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!template.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Pasif', style: TextStyle(fontSize: 11)),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
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
