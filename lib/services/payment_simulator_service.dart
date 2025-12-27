import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/payment_simulation.dart';
import '../repositories/credit_card_repository.dart';
import 'credit_card_service.dart';
class PaymentSimulatorService {
  final CreditCardRepository _cardRepo = CreditCardRepository();
  final CreditCardService _cardService = CreditCardService();
  final Uuid _uuid = const Uuid();
  Future<PaymentSimulation> simulatePayment({
    required String cardId,
    required double paymentAmount,
  }) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }
    final currentDebt = await _cardService.getCurrentDebt(cardId);
    if (paymentAmount < 0) {
      throw Exception('Ödeme tutarı negatif olamaz');
    }

    if (paymentAmount > currentDebt) {
      throw Exception('Ödeme tutarı mevcut borçtan fazla olamaz');
    }
    final remainingDebt = currentDebt - paymentAmount;
    final monthlyInterestRate = card.monthlyInterestRate / 100;
    final interestCharged = remainingDebt * monthlyInterestRate;
    int monthsToPayoff = 0;
    double totalCost = 0.0;
    double debt = currentDebt;
    
    if (paymentAmount > 0 && currentDebt > 0) {
      while (debt > 0.01 && monthsToPayoff < 1000) {
        monthsToPayoff++;
        final interest = debt * monthlyInterestRate;
        debt = debt + interest;
        if (paymentAmount <= interest) {
          monthsToPayoff = -1;
          totalCost = double.infinity;
          break;
        }
        if (debt <= paymentAmount) {
          totalCost += debt;
          debt = 0;
          break;
        } else {
          totalCost += paymentAmount;
          debt -= paymentAmount;
        }
      }
    } else if (currentDebt <= 0.01) {
      totalCost = 0;
      monthsToPayoff = 0;
    }
    final simulation = PaymentSimulation(
      id: _uuid.v4(),
      cardId: cardId,
      currentDebt: currentDebt,
      proposedPayment: paymentAmount,
      remainingDebt: remainingDebt,
      interestCharged: interestCharged,
      monthsToPayoff: monthsToPayoff,
      totalCost: totalCost,
      simulationDate: DateTime.now(),
    );

    return simulation;
  }
  Future<Map<String, dynamic>> simulateMinimumPayment(String cardId) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }
    final currentDebt = await _cardService.getCurrentDebt(cardId);

    if (currentDebt <= 0) {
      return {
        'currentDebt': 0.0,
        'minimumPayment': 0.0,
        'remainingDebt': 0.0,
        'interestCharged': 0.0,
        'monthsToPayoff': 0,
        'totalCost': 0.0,
        'message': 'Borç bulunmamaktadır',
      };
    }
    final minimumPayment = max(currentDebt * 0.33, 100.0);
    final simulation = await simulatePayment(
      cardId: cardId,
      paymentAmount: minimumPayment,
    );

    return {
      'currentDebt': currentDebt,
      'minimumPayment': minimumPayment,
      'remainingDebt': simulation.remainingDebt,
      'interestCharged': simulation.interestCharged,
      'monthsToPayoff': simulation.monthsToPayoff,
      'totalCost': simulation.totalCost,
      'monthlyInterestRate': card.monthlyInterestRate,
      'message': simulation.monthsToPayoff == -1
          ? 'Asgari ödeme ile borç kapatılamaz'
          : 'Asgari ödeme ile ${simulation.monthsToPayoff} ayda kapatılır',
    };
  }
  Future<Map<String, dynamic>> simulateFullPayment(String cardId) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }
    final currentDebt = await _cardService.getCurrentDebt(cardId);

    if (currentDebt <= 0) {
      return {
        'currentDebt': 0.0,
        'fullPayment': 0.0,
        'remainingDebt': 0.0,
        'interestCharged': 0.0,
        'monthsToPayoff': 0,
        'totalCost': 0.0,
        'interestSaved': 0.0,
        'message': 'Borç bulunmamaktadır',
      };
    }
    final fullPayment = currentDebt;
    final minimumSimulation = await simulateMinimumPayment(cardId);
    final interestSaved = minimumSimulation['totalCost'] - fullPayment;

    return {
      'currentDebt': currentDebt,
      'fullPayment': fullPayment,
      'remainingDebt': 0.0,
      'interestCharged': 0.0,
      'monthsToPayoff': 0,
      'totalCost': fullPayment,
      'interestSaved': interestSaved > 0 ? interestSaved : 0.0,
      'message': 'Tam ödeme ile borç hemen kapatılır',
    };
  }
  Future<Map<String, dynamic>> simulateEarlyPayoff(String cardId) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }
    final currentDebt = await _cardService.getCurrentDebt(cardId);

    if (currentDebt <= 0) {
      return {
        'currentDebt': 0.0,
        'earlyPayoffAmount': 0.0,
        'interestSaved': 0.0,
        'monthsSaved': 0,
        'message': 'Borç bulunmamaktadır',
      };
    }
    final minimumSimulation = await simulateMinimumPayment(cardId);

    final interestSaved = minimumSimulation['totalCost'] - currentDebt;
    final monthsSaved = minimumSimulation['monthsToPayoff'];

    return {
      'currentDebt': currentDebt,
      'earlyPayoffAmount': currentDebt,
      'interestSaved': interestSaved > 0 ? interestSaved : 0.0,
      'monthsSaved': monthsSaved > 0 ? monthsSaved : 0,
      'minimumPaymentTotalCost': minimumSimulation['totalCost'],
      'fullPaymentTotalCost': currentDebt,
      'message': interestSaved > 0
          ? 'Erken kapatma ile ₺${interestSaved.toStringAsFixed(2)} faiz tasarrufu'
          : 'Erken kapatma önerilir',
    };
  }
  Future<Map<String, dynamic>> comparePaymentOptions(
    String cardId,
    List<double> paymentAmounts,
  ) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }
    final currentDebt = await _cardService.getCurrentDebt(cardId);

    if (currentDebt <= 0) {
      return {
        'currentDebt': 0.0,
        'comparisons': [],
        'message': 'Borç bulunmamaktadır',
      };
    }
    final comparisons = <Map<String, dynamic>>[];
    
    for (final amount in paymentAmounts) {
      if (amount > currentDebt) {
        continue;
      }

      try {
        final simulation = await simulatePayment(
          cardId: cardId,
          paymentAmount: amount,
        );

        comparisons.add({
          'paymentAmount': amount,
          'remainingDebt': simulation.remainingDebt,
          'interestCharged': simulation.interestCharged,
          'monthsToPayoff': simulation.monthsToPayoff,
          'totalCost': simulation.totalCost,
        });
      } catch (e) {
        continue;
      }
    }
    comparisons.sort((a, b) => 
      (a['totalCost'] as double).compareTo(b['totalCost'] as double));

    return {
      'currentDebt': currentDebt,
      'comparisons': comparisons,
      'bestOption': comparisons.isNotEmpty ? comparisons.first : null,
      'worstOption': comparisons.isNotEmpty ? comparisons.last : null,
      'message': 'Karşılaştırma tamamlandı',
    };
  }
  Future<double> calculateInterestSavings({
    required String cardId,
    required double proposedPayment,
  }) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }
    final currentDebt = await _cardService.getCurrentDebt(cardId);

    if (currentDebt <= 0 || proposedPayment <= 0) {
      return 0.0;
    }
    final minimumSimulation = await simulateMinimumPayment(cardId);
    final proposedSimulation = await simulatePayment(
      cardId: cardId,
      paymentAmount: proposedPayment,
    );
    final minimumTotalCost = minimumSimulation['totalCost'] as double;
    final proposedTotalCost = proposedSimulation.totalCost;

    final savings = minimumTotalCost - proposedTotalCost;

    return savings > 0 ? savings : 0.0;
  }
  Future<Map<String, dynamic>> getPaymentRecommendation(String cardId) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }
    final currentDebt = await _cardService.getCurrentDebt(cardId);

    if (currentDebt <= 0) {
      return {
        'recommendation': 'no_debt',
        'message': 'Borç bulunmamaktadır',
        'suggestedPayment': 0.0,
      };
    }
    final minimumPayment = max(currentDebt * 0.33, 100.0);
    final recommendedPayment = currentDebt * 0.50;
    final minimumSimulation = await simulateMinimumPayment(cardId);
    final recommendedSimulation = await simulatePayment(
      cardId: cardId,
      paymentAmount: recommendedPayment,
    );

    final interestSavings = minimumSimulation['totalCost'] - 
                           recommendedSimulation.totalCost;

    return {
      'recommendation': 'partial_payment',
      'currentDebt': currentDebt,
      'minimumPayment': minimumPayment,
      'recommendedPayment': recommendedPayment,
      'fullPayment': currentDebt,
      'minimumMonths': minimumSimulation['monthsToPayoff'],
      'recommendedMonths': recommendedSimulation.monthsToPayoff,
      'interestSavings': interestSavings > 0 ? interestSavings : 0.0,
      'message': 'Önerilen ödeme: ₺${recommendedPayment.toStringAsFixed(2)}',
    };
  }
}
