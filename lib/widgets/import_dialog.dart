import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/import_result.dart';
import '../services/qif_service.dart';
import '../services/ofx_service.dart';
import '../services/import_validation_service.dart';
import '../services/data_service.dart';

class ImportDialog extends StatefulWidget {
  const ImportDialog({super.key});

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  final QifService _qifService = QifService();
  final OfxService _ofxService = OfxService();
  final ImportValidationService _validationService = ImportValidationService();
  final DataService _dataService = DataService();

  String? _selectedFilePath;
  String? _selectedFormat;
  bool _isLoading = false;
  ImportResult? _importResult;
  bool _showPreview = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('İçe Aktar'),
      content: SizedBox(width: double.maxFinite, child: _buildContent()),
      actions: _buildActions(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('İçe aktarılıyor...'),
          ],
        ),
      );
    }

    if (_importResult != null) {
      return _buildResultView();
    }

    if (_showPreview && _selectedFilePath != null) {
      return _buildPreviewView();
    }

    return _buildFileSelectionView();
  }

  Widget _buildFileSelectionView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Desteklenen formatlar: QIF, OFX, CSV',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        if (_selectedFilePath != null) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: Text(_selectedFilePath!.split('/').last),
              subtitle: Text(
                'Format: ${_selectedFormat?.toUpperCase() ?? "Bilinmiyor"}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedFilePath = null;
                    _selectedFormat = null;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        ElevatedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.folder_open),
          label: const Text('Dosya Seç'),
        ),
      ],
    );
  }

  Widget _buildPreviewView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Önizleme',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.insert_drive_file),
            title: Text(_selectedFilePath!.split('/').last),
            subtitle: Text(
              'Format: ${_selectedFormat?.toUpperCase() ?? "Bilinmiyor"}',
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Dosya içe aktarılmaya hazır. Devam etmek istiyor musunuz?',
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    final result = _importResult!;
    final hasErrors = result.hasErrors;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: hasErrors ? Colors.orange.shade50 : Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        hasErrors ? Icons.warning : Icons.check_circle,
                        color: hasErrors ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasErrors ? 'Kısmi Başarı' : 'Başarılı',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: hasErrors ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Başarılı: ${result.successCount}'),
                  if (result.failureCount > 0)
                    Text('Başarısız: ${result.failureCount}'),
                  Text('Toplam: ${result.totalCount}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (hasErrors) ...[
            const Text(
              'Hatalar:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: result.errors.length,
                itemBuilder: (context, index) {
                  final error = result.errors[index];
                  return Card(
                    color: Colors.red.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.error, color: Colors.red),
                      title: Text('Satır ${error.rowNumber}'),
                      subtitle: Text('${error.field}: ${error.message}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    if (_importResult != null) {
      return [
        TextButton(
          onPressed: () =>
              Navigator.pop(context, _importResult!.successCount > 0),
          child: const Text('Kapat'),
        ),
      ];
    }

    if (_showPreview && _selectedFilePath != null) {
      return [
        TextButton(
          onPressed: () {
            setState(() {
              _showPreview = false;
            });
          },
          child: const Text('Geri'),
        ),
        ElevatedButton(
          onPressed: _performImport,
          child: const Text('İçe Aktar'),
        ),
      ];
    }

    return [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('İptal'),
      ),
      ElevatedButton(
        onPressed: _selectedFilePath != null ? _showPreviewScreen : null,
        child: const Text('Devam'),
      ),
    ];
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['qif', 'ofx', 'qfx', 'csv'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final format = _validationService.detectFileFormat(filePath);

        setState(() {
          _selectedFilePath = filePath;
          _selectedFormat = format;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya seçme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPreviewScreen() {
    setState(() {
      _showPreview = true;
    });
  }

  Future<void> _performImport() async {
    if (_selectedFilePath == null || _selectedFormat == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final wallets = await _dataService.getWallets();
      if (wallets.isEmpty) {
        throw Exception('Lütfen önce bir cüzdan oluşturun');
      }
      final defaultWalletId = wallets.first.id;
      final existingTransactions = await _dataService.getTransactions();
      final existingIds = existingTransactions.map((t) => t.id).toList();
      ImportResult result;
      switch (_selectedFormat) {
        case 'qif':
          result = await _qifService.importFromQif(
            filePath: _selectedFilePath!,
            defaultWalletId: defaultWalletId,
          );
          break;
        case 'ofx':
          result = await _ofxService.importFromOfx(
            filePath: _selectedFilePath!,
            defaultWalletId: defaultWalletId,
            existingTransactionIds: existingIds,
          );
          break;
        default:
          throw Exception('Desteklenmeyen format: $_selectedFormat');
      }
      if (result.importedTransactions.isNotEmpty) {
        for (var transaction in result.importedTransactions) {
          await _dataService.addTransaction(transaction);
        }
      }

      setState(() {
        _importResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İçe aktarma hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
