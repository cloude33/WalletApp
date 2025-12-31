import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/report_data.dart';
import '../../models/cash_flow_data.dart';
import '../../models/transaction.dart';
import '../../services/report_service.dart';
import 'summary_card.dart';
import 'metric_card.dart';
import 'income_report_widget.dart';
import 'export_options_widget.dart';
class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  final ReportService _reportService = ReportService();
  ReportType _selectedReportType = ReportType.income;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  ReportPeriod _selectedPeriod = ReportPeriod.monthly;
  List<String>? _selectedCategories;
  List<String>? _selectedWallets;
  bool _includeIncome = true;
  bool _includeExpenses = true;
  bool _includeBills = true;
  bool _includePreviousPeriod = false;
  ReportData? _currentReport;
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildConfigurationSection(),
          
          const Divider(height: 1),
          Expanded(
            child: _buildReportPreview(),
          ),
        ],
      ),
    );
  }
  Widget _buildConfigurationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReportTypeSelector(),
          
          const SizedBox(height: 16),
          _buildDateRangeSelector(),
          
          const SizedBox(height: 16),
          _buildFilterOptions(),
          
          const SizedBox(height: 16),
          _buildGenerateButton(),
        ],
      ),
    );
  }
  Widget _buildReportTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rapor Tipi',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildReportTypeChip(
              type: ReportType.income,
              label: 'Gelir Raporu',
              icon: Icons.trending_up,
            ),
            _buildReportTypeChip(
              type: ReportType.expense,
              label: 'Gider Raporu',
              icon: Icons.trending_down,
            ),
            _buildReportTypeChip(
              type: ReportType.bill,
              label: 'Fatura Raporu',
              icon: Icons.receipt_long,
            ),
            _buildReportTypeChip(
              type: ReportType.custom,
              label: 'Özel Rapor',
              icon: Icons.tune,
            ),
          ],
        ),
      ],
    );
  }
  Widget _buildReportTypeChip({
    required ReportType type,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedReportType == type;
    
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedReportType = type;
            _currentReport = null;
          });
        }
      },
    );
  }
  Widget _buildDateRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tarih Aralığı',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPeriodChip(ReportPeriod.monthly, 'Bu Ay'),
            _buildPeriodChip(ReportPeriod.quarterly, 'Son 3 Ay'),
            _buildPeriodChip(ReportPeriod.yearly, 'Bu Yıl'),
            _buildPeriodChip(ReportPeriod.custom, 'Özel'),
          ],
        ),
        
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateButton(
                label: 'Başlangıç',
                date: _startDate,
                onTap: () => _selectDate(context, true),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDateButton(
                label: 'Bitiş',
                date: _endDate,
                onTap: () => _selectDate(context, false),
              ),
            ),
          ],
        ),
      ],
    );
  }
  Widget _buildPeriodChip(ReportPeriod period, String label) {
    final isSelected = _selectedPeriod == period;
    
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPeriod = period;
            _updateDateRangeForPeriod(period);
            _currentReport = null;
          });
        }
      },
    );
  }
  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMM yyyy').format(date),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildFilterOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Filtreler',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _showFilterDialog,
              icon: const Icon(Icons.filter_list, size: 18),
              label: Text(
                _getFilterSummary(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        if (_selectedReportType == ReportType.custom) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                selected: _includeIncome,
                label: const Text('Gelir'),
                onSelected: (selected) {
                  setState(() {
                    _includeIncome = selected;
                    _currentReport = null;
                  });
                },
              ),
              FilterChip(
                selected: _includeExpenses,
                label: const Text('Gider'),
                onSelected: (selected) {
                  setState(() {
                    _includeExpenses = selected;
                    _currentReport = null;
                  });
                },
              ),
              FilterChip(
                selected: _includeBills,
                label: const Text('Faturalar'),
                onSelected: (selected) {
                  setState(() {
                    _includeBills = selected;
                    _currentReport = null;
                  });
                },
              ),
            ],
          ),
        ],
        if (_selectedReportType == ReportType.income ||
            _selectedReportType == ReportType.expense) ...[
          const SizedBox(height: 8),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Önceki dönemle karşılaştır'),
            value: _includePreviousPeriod,
            onChanged: (value) {
              setState(() {
                _includePreviousPeriod = value ?? false;
                _currentReport = null;
              });
            },
          ),
        ],
      ],
    );
  }
  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _generateReport,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.assessment),
        label: Text(_isLoading ? 'Oluşturuluyor...' : 'Rapor Oluştur'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
  Widget _buildReportPreview() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Hata',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generateReport,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_currentReport == null) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.assessment_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Rapor Oluşturun',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Yukarıdaki seçenekleri kullanarak\nrapor oluşturabilirsiniz',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReportHeader(),
          
          const SizedBox(height: 16),
          _buildReportContent(),
          
          const SizedBox(height: 24),
          _buildExportOptions(),
        ],
      ),
    );
  }
  Widget _buildReportHeader() {
    if (_currentReport == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getReportIcon(),
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentReport!.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('dd MMM yyyy').format(_currentReport!.startDate)} - '
                        '${DateFormat('dd MMM yyyy').format(_currentReport!.endDate)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Oluşturulma: ${DateFormat('dd MMM yyyy HH:mm').format(_currentReport!.generatedAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildReportContent() {
    if (_currentReport == null) return const SizedBox.shrink();

    switch (_currentReport!.type) {
      case ReportType.income:
        return _buildIncomeReportContent(_currentReport as IncomeReport);
      case ReportType.expense:
        return _buildExpenseReportContent(_currentReport as ExpenseReport);
      case ReportType.bill:
        return _buildBillReportContent(_currentReport as BillReport);
      case ReportType.custom:
        return _buildCustomReportContent(_currentReport as CustomReport);
    }
  }
  Widget _buildIncomeReportContent(IncomeReport report) {
    return IncomeReportWidget(report: report);
  }
  Widget _buildExpenseReportContent(ExpenseReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Toplam Gider',
                value: '₺${NumberFormat('#,##0.00', 'tr_TR').format(report.totalExpense)}',
                icon: Icons.trending_down,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SummaryCard(
                title: 'Aylık Ortalama',
                value: '₺${NumberFormat('#,##0.00', 'tr_TR').format(report.averageMonthly)}',
                icon: Icons.calendar_today,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Sabit Giderler',
                value: '₺${NumberFormat('#,##0.00', 'tr_TR').format(report.totalFixedExpense)}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MetricCard(
                label: 'Değişken Giderler',
                value: '₺${NumberFormat('#,##0.00', 'tr_TR').format(report.totalVariableExpense)}',
              ),
            ),
          ],
        ),
        
        if (report.changePercentage != null) ...[
          const SizedBox(height: 8),
          MetricCard(
            label: 'Önceki Döneme Göre',
            value: '${report.changePercentage! >= 0 ? '+' : ''}${report.changePercentage!.toStringAsFixed(1)}%',
            trend: report.changePercentage! >= 0 
                ? TrendDirection.up 
                : TrendDirection.down,
            color: report.changePercentage! >= 0 ? Colors.red : Colors.green,
          ),
        ],
        
        const SizedBox(height: 16),
        Text(
          'Kategori Dağılımı',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        ...report.expenseCategories.map((category) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: category.isFixed 
                  ? Colors.blue.shade100 
                  : Colors.orange.shade100,
              child: Text(
                '${category.percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: category.isFixed 
                      ? Colors.blue.shade700 
                      : Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: Row(
              children: [
                Text(category.category),
                const SizedBox(width: 8),
                if (category.isFixed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Sabit',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text('${category.transactionCount} işlem'),
            trailing: Text(
              '₺${NumberFormat('#,##0.00', 'tr_TR').format(category.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        )),
        if (report.optimizationSuggestions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Optimizasyon Önerileri',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          ...report.optimizationSuggestions.map((suggestion) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.amber.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion.category,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                      Text(
                        'Tasarruf: ₺${NumberFormat('#,##0', 'tr_TR').format(suggestion.potentialSavings)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    suggestion.suggestion,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ],
    );
  }
  Widget _buildBillReportContent(BillReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Toplam Ödenen',
                value: '₺${NumberFormat('#,##0.00', 'tr_TR').format(report.totalPaid)}',
                icon: Icons.receipt_long,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SummaryCard(
                title: 'Fatura Sayısı',
                value: report.billCount.toString(),
                icon: Icons.numbers,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Zamanında Ödenen',
                value: '${report.onTimePercentage.toStringAsFixed(1)}%',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MetricCard(
                label: 'Ortalama Tutar',
                value: '₺${NumberFormat('#,##0.00', 'tr_TR').format(report.averageBillAmount)}',
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        Text(
          'Fatura Ödemeleri',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        if (report.billPayments.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('Bu dönemde fatura ödemesi bulunamadı'),
              ),
            ),
          )
        else
          ...report.billPayments.map((bill) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: bill.onTime 
                    ? Colors.green.shade100 
                    : Colors.red.shade100,
                child: Icon(
                  bill.onTime ? Icons.check : Icons.warning,
                  color: bill.onTime 
                      ? Colors.green.shade700 
                      : Colors.red.shade700,
                ),
              ),
              title: Text(bill.billName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bill.category),
                  Text(
                    'Ödeme: ${DateFormat('dd MMM yyyy').format(bill.paymentDate)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              trailing: Text(
                '₺${NumberFormat('#,##0.00', 'tr_TR').format(bill.amount)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          )),
      ],
    );
  }
  Widget _buildCustomReportContent(CustomReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (report.totalIncome != null)
              SizedBox(
                width: (MediaQuery.of(context).size.width - 48) / 2,
                child: SummaryCard(
                  title: 'Toplam Gelir',
                  value: '₺${NumberFormat('#,##0.00', 'tr_TR').format(report.totalIncome)}',
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
              ),
            if (report.totalExpense != null)
              SizedBox(
                width: (MediaQuery.of(context).size.width - 48) / 2,
                child: SummaryCard(
                  title: 'Toplam Gider',
                  value: '₺${NumberFormat('#,##0.00', 'tr_TR').format(report.totalExpense)}',
                  icon: Icons.trending_down,
                  color: Colors.red,
                ),
              ),
            if (report.totalBills != null)
              SizedBox(
                width: (MediaQuery.of(context).size.width - 48) / 2,
                child: SummaryCard(
                  title: 'Toplam Faturalar',
                  value: '₺${NumberFormat('#,##0.00', 'tr_TR').format(report.totalBills)}',
                  icon: Icons.receipt_long,
                  color: Colors.purple,
                ),
              ),
            SizedBox(
              width: (MediaQuery.of(context).size.width - 48) / 2,
              child: SummaryCard(
                title: 'Net Tutar',
                value: '₺${NumberFormat('#,##0.00', 'tr_TR').format(report.netAmount)}',
                icon: Icons.account_balance_wallet,
                color: report.netAmount >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        MetricCard(
          label: 'İşlem Sayısı',
          value: report.transactionCount.toString(),
        ),
        if (report.categoryBreakdown.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Kategori Dağılımı',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          ...report.categoryBreakdown.entries.map((entry) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(entry.key),
              trailing: Text(
                '₺${NumberFormat('#,##0.00', 'tr_TR').format(entry.value)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          )),
        ],
        if (report.walletBreakdown.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Cüzdan Dağılımı',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          ...report.walletBreakdown.entries.map((entry) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: Text(entry.key),
              trailing: Text(
                '₺${NumberFormat('#,##0.00', 'tr_TR').format(entry.value)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          )),
        ],
      ],
    );
  }
  Widget _buildExportOptions() {
    return ExportOptionsWidget(
      report: _currentReport,
      transactions: _getTransactionsForExport(),
      onExportComplete: () {
      },
    );
  }
  List<Transaction>? _getTransactionsForExport() {
    return null;
  }
  String _getFilterSummary() {
    final filters = <String>[];
    
    if (_selectedCategories != null && _selectedCategories!.isNotEmpty) {
      filters.add('${_selectedCategories!.length} kategori');
    }
    
    if (_selectedWallets != null && _selectedWallets!.isNotEmpty) {
      filters.add('${_selectedWallets!.length} cüzdan');
    }
    
    if (filters.isEmpty) {
      return 'Tümü';
    }
    
    return filters.join(', ');
  }
  IconData _getReportIcon() {
    switch (_selectedReportType) {
      case ReportType.income:
        return Icons.trending_up;
      case ReportType.expense:
        return Icons.trending_down;
      case ReportType.bill:
        return Icons.receipt_long;
      case ReportType.custom:
        return Icons.tune;
    }
  }
  void _updateDateRangeForPeriod(ReportPeriod period) {
    final now = DateTime.now();
    
    switch (period) {
      case ReportPeriod.monthly:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case ReportPeriod.quarterly:
        _startDate = DateTime(now.year, now.month - 2, 1);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case ReportPeriod.yearly:
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case ReportPeriod.custom:
        break;
      default:
        break;
    }
  }
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('tr', 'TR'),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            23,
            59,
            59,
          );
        }
        _selectedPeriod = ReportPeriod.custom;
        _currentReport = null;
      });
    }
  }
  Future<void> _showFilterDialog() async {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filtre seçenekleri yakında eklenecek'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      ReportData report;

      switch (_selectedReportType) {
        case ReportType.income:
          report = await _reportService.generateIncomeReport(
            startDate: _startDate,
            endDate: _endDate,
            includePreviousPeriod: _includePreviousPeriod,
          );
          break;

        case ReportType.expense:
          report = await _reportService.generateExpenseReport(
            startDate: _startDate,
            endDate: _endDate,
            includePreviousPeriod: _includePreviousPeriod,
          );
          break;

        case ReportType.bill:
          report = await _reportService.generateBillReport(
            startDate: _startDate,
            endDate: _endDate,
            includeUpcoming: true,
          );
          break;

        case ReportType.custom:
          final filters = CustomReportFilters(
            startDate: _startDate,
            endDate: _endDate,
            categories: _selectedCategories,
            walletIds: _selectedWallets,
            includeIncome: _includeIncome,
            includeExpenses: _includeExpenses,
            includeBills: _includeBills,
          );
          report = await _reportService.generateCustomReport(filters: filters);
          break;
      }

      setState(() {
        _currentReport = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }


}
