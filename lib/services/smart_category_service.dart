import '../models/transaction.dart';
import '../models/category.dart';
import 'data_service.dart';

class SmartCategoryService {
  static final SmartCategoryService _instance =
      SmartCategoryService._internal();
  factory SmartCategoryService() => _instance;
  SmartCategoryService._internal();

  final DataService _dataService = DataService();
  Future<CategorySuggestion?> suggestCategory(
    String description,
    String type,
  ) async {
    if (description.trim().isEmpty) return null;

    final transactions = await _dataService.getTransactions();
    final categories = (await _dataService.getCategories()).cast<Category>();
    final relevantTransactions = transactions
        .where((t) => t.type == type)
        .toList();

    if (relevantTransactions.isEmpty) return null;
    final suggestions = <CategorySuggestion>[];
    final exactMatch = _findExactMatch(description, relevantTransactions);
    if (exactMatch != null) {
      suggestions.add(
        CategorySuggestion(
          category: exactMatch,
          confidence: 1.0,
          reason: 'Tam eşleşme',
          matchedTransactions: _getMatchingTransactions(
            description,
            relevantTransactions,
            exactMatch,
          ),
        ),
      );
    }
    final partialMatches = _findPartialMatches(
      description,
      relevantTransactions,
      categories,
    );
    suggestions.addAll(partialMatches);
    final keywordMatches = _findKeywordMatches(description, type, categories);
    suggestions.addAll(keywordMatches);

    if (suggestions.isEmpty) return null;
    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return suggestions.first;
  }
  String? _findExactMatch(String description, List<Transaction> transactions) {
    final normalized = _normalizeText(description);

    for (var transaction in transactions) {
      if (_normalizeText(transaction.description) == normalized) {
        return transaction.category;
      }
    }

    return null;
  }
  List<CategorySuggestion> _findPartialMatches(
    String description,
    List<Transaction> transactions,
    List<Category> categories,
  ) {
    final suggestions = <CategorySuggestion>[];
    final descWords = _extractWords(description);

    if (descWords.isEmpty) return suggestions;
    final categoryScores = <String, CategoryScore>{};

    for (var transaction in transactions) {
      final transWords = _extractWords(transaction.description);
      final similarity = _calculateSimilarity(descWords, transWords);

      if (similarity > 0.3) {
        final category = transaction.category;
        if (!categoryScores.containsKey(category)) {
          categoryScores[category] = CategoryScore(
            category: category,
            totalScore: 0,
            count: 0,
            matchedTransactions: [],
          );
        }

        categoryScores[category]!.totalScore += similarity;
        categoryScores[category]!.count++;
        categoryScores[category]!.matchedTransactions.add(transaction);
      }
    }
    for (var entry in categoryScores.entries) {
      final avgScore = entry.value.totalScore / entry.value.count;
      final confidence = avgScore * (entry.value.count / transactions.length);

      if (confidence > 0.2) {
        suggestions.add(
          CategorySuggestion(
            category: entry.key,
            confidence: confidence,
            reason: '${entry.value.count} benzer işlem',
            matchedTransactions: entry.value.matchedTransactions
                .take(3)
                .toList(),
          ),
        );
      }
    }

    return suggestions;
  }
  List<CategorySuggestion> _findKeywordMatches(
    String description,
    String type,
    List<Category> categories,
  ) {
    final suggestions = <CategorySuggestion>[];
    final normalized = _normalizeText(description);
    final keywordMap = _getKeywordMap(type);

    for (var entry in keywordMap.entries) {
      final categoryName = entry.key;
      final keywords = entry.value;

      for (var keyword in keywords) {
        if (normalized.contains(_normalizeText(keyword))) {
          final categoryExists = categories.any(
            (c) => c.name == categoryName && c.type == type,
          );

          if (categoryExists) {
            suggestions.add(
              CategorySuggestion(
                category: categoryName,
                confidence: 0.7,
                reason: 'Anahtar kelime: "$keyword"',
                matchedTransactions: [],
              ),
            );
            break;
          }
        }
      }
    }

    return suggestions;
  }
  Map<String, List<String>> _getKeywordMap(String type) {
    if (type == 'expense') {
      return {
        'Yiyecek': [
          'market',
          'süpermarket',
          'migros',
          'a101',
          'bim',
          'şok',
          'carrefour',
          'yemek',
          'restaurant',
          'restoran',
          'cafe',
          'kahve',
        ],
        'Ulaşım': [
          'benzin',
          'akaryakıt',
          'otobüs',
          'metro',
          'taksi',
          'uber',
          'bitaksi',
          'otopark',
        ],
        'Faturalar': [
          'elektrik',
          'su',
          'doğalgaz',
          'internet',
          'telefon',
          'fatura',
          'aidat',
        ],
        'Sağlık': ['eczane', 'hastane', 'doktor', 'ilaç', 'sağlık', 'diş'],
        'Eğlence': [
          'sinema',
          'konser',
          'tiyatro',
          'netflix',
          'spotify',
          'eğlence',
        ],
        'Giyim': [
          'giyim',
          'ayakkabı',
          'kıyafet',
          'zara',
          'h&m',
          'mango',
          'lcwaikiki',
        ],
        'Eğitim': ['okul', 'kurs', 'kitap', 'eğitim', 'üniversite'],
        'Alışveriş': [
          'amazon',
          'trendyol',
          'hepsiburada',
          'n11',
          'gittigidiyor',
        ],
        'Fitness': ['spor', 'fitness', 'gym', 'yoga', 'pilates'],
      };
    } else {
      return {
        'Maaş': ['maaş', 'ücret', 'salary', 'gelir'],
        'Yatırım': ['yatırım', 'hisse', 'borsa', 'kripto', 'bitcoin'],
        'Hediye': ['hediye', 'gift'],
        'Ödül': ['ödül', 'bonus', 'prim'],
      };
    }
  }
  List<Transaction> _getMatchingTransactions(
    String description,
    List<Transaction> transactions,
    String category,
  ) {
    final normalized = _normalizeText(description);
    final descWords = _extractWords(description);

    return transactions
        .where((t) => t.category == category)
        .where((t) {
          final transNormalized = _normalizeText(t.description);
          final transWords = _extractWords(t.description);

          return transNormalized == normalized ||
              _calculateSimilarity(descWords, transWords) > 0.5;
        })
        .take(5)
        .toList();
  }
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
  List<String> _extractWords(String text) {
    final normalized = _normalizeText(text);
    final words = normalized.split(' ');
    final stopWords = {'ve', 'ile', 'için', 'bir', 'bu', 'şu', 'o', 'de', 'da'};

    return words.where((w) => w.length > 2 && !stopWords.contains(w)).toList();
  }
  double _calculateSimilarity(List<String> words1, List<String> words2) {
    if (words1.isEmpty || words2.isEmpty) return 0.0;

    final set1 = words1.toSet();
    final set2 = words2.toSet();

    final intersection = set1.intersection(set2).length;
    final union = set1.union(set2).length;

    return union > 0 ? intersection / union : 0.0;
  }
  Future<Map<String, CategoryStats>> getCategoryStats(String type) async {
    final transactions = await _dataService.getTransactions();
    final stats = <String, CategoryStats>{};

    for (var transaction in transactions.where((t) => t.type == type)) {
      if (!stats.containsKey(transaction.category)) {
        stats[transaction.category] = CategoryStats(
          category: transaction.category,
          count: 0,
          totalAmount: 0,
          descriptions: {},
        );
      }

      stats[transaction.category]!.count++;
      stats[transaction.category]!.totalAmount += transaction.amount;

      final normalized = _normalizeText(transaction.description);
      stats[transaction.category]!.descriptions[normalized] =
          (stats[transaction.category]!.descriptions[normalized] ?? 0) + 1;
    }

    return stats;
  }
  Future<List<Transaction>> findSimilarTransactions(
    String description,
    String type,
  ) async {
    final transactions = await _dataService.getTransactions();
    final descWords = _extractWords(description);

    if (descWords.isEmpty) return [];

    final similar = <TransactionSimilarity>[];

    for (var transaction in transactions.where((t) => t.type == type)) {
      final transWords = _extractWords(transaction.description);
      final similarity = _calculateSimilarity(descWords, transWords);

      if (similarity > 0.3) {
        similar.add(
          TransactionSimilarity(
            transaction: transaction,
            similarity: similarity,
          ),
        );
      }
    }

    similar.sort((a, b) => b.similarity.compareTo(a.similarity));
    return similar.take(10).map((s) => s.transaction).toList();
  }
}
class CategorySuggestion {
  final String category;
  final double confidence;
  final String reason;
  final List<Transaction> matchedTransactions;

  CategorySuggestion({
    required this.category,
    required this.confidence,
    required this.reason,
    required this.matchedTransactions,
  });
}

class CategoryScore {
  final String category;
  double totalScore;
  int count;
  List<Transaction> matchedTransactions;

  CategoryScore({
    required this.category,
    required this.totalScore,
    required this.count,
    required this.matchedTransactions,
  });
}

class CategoryStats {
  final String category;
  int count;
  double totalAmount;
  Map<String, int> descriptions;

  CategoryStats({
    required this.category,
    required this.count,
    required this.totalAmount,
    required this.descriptions,
  });

  double get averageAmount => count > 0 ? totalAmount / count : 0;
}

class TransactionSimilarity {
  final Transaction transaction;
  final double similarity;

  TransactionSimilarity({required this.transaction, required this.similarity});
}
