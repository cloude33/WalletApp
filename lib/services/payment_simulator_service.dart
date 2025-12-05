import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/payment_simulation.dart';
import '../repositories/credit_card_repository.dart';
import 'credit_card_service.dart';

/// Service for simulating payment scenarios and calculating interest
class PaymentSimulatorService {
  final CreditCardRepository _cardRepo = CreditCardRepository();
  final CreditCardService _cardService = CreditCardService();
  final Uuid _uuid = const Uuid();

  /// Simulate a payment scenario
  /// Returns a PaymentSimulation with calculated interest and remaining debt
  Future<PaymentSimulation> simulatePayment({
    required String cardId,
    required double paymentAmount,
  }) async {
    // Get card
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    // Get current debt
    final currentDebt = await _cardService.getCurrentDebt(cardId);

    // Validate payment amount
    if (paymentAmount < 0) {
      throw Exception('Ödeme tutarı negatif olamaz');
    }

    if (paymentAmount > currentDebt) {
      throw Exception('Ödeme tutarı mevcut borçtan fazla olamaz');
    }

    // Calculate remaining debt after payment
    final remainingDebt = currentDebt - paymentAmount;

    // Calculate interest on remaining debt (monthly interest rate)
    final monthlyInterestRate = card.monthlyInterestRate / 100;
    final interestCharged = remainingDebt * monthlyInterestRate;

    // Calculate months to payoff and total cost if continuing with same payment amount
    int monthsToPayoff = 0;
    double totalCost = 0.0;
    double debt = currentDebt; // Start from current debt, not remaining
    
    if (paymentAmount > 0 && currentDebt > 0) {
      // Simulate monthly payments until debt is paid off
      while (debt > 0.01 && monthsToPayoff < 1000) { // Max 1000 months to prevent infinite loop
        monthsToPayoff++;
        
        // Calculate interest on current debt
        final interest = debt * monthlyInterestRate;
        
        // Add interest to debt
        debt = debt + interest;
        
        // If payment doesn't cover interest, debt will never be paid off
        if (paymentAmount <= interest) {
          monthsToPayoff = -1; // Indicate impossible to pay off
          totalCost = double.infinity;
          break;
        }
        
        // Make payment
        if (debt <= paymentAmount) {
          // Last payment - only pay what's needed
          totalCost += debt;
          debt = 0;
          break;
        } else {
          // Regular payment
          totalCost += paymentAmount;
          debt -= paymentAmount;
        }
      }
    } else if (currentDebt <= 0.01) {
      // No debt
      totalCost = 0;
      monthsToPayoff = 0;
    }

    // Create simulation
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

  /// Simulate minimum payment scenario
  /// Returns a map with simulation details
  Future<Map<String, dynamic>> simulateMinimumPayment(String cardId) async {
    // Get card
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    // Get current debt
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

    // Calculate minimum payment (typically 33% of debt or a minimum amount)
    final minimumPayment = max(currentDebt * 0.33, 100.0);

    // Simulate with minimum payment
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

  /// Simulate full payment scenario
  /// Returns a map with simulation details
  Future<Map<String, dynamic>> simulateFullPayment(String cardId) async {
    // Get card
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    // Get current debt
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

    // Full payment means paying entire debt
    final fullPayment = currentDebt;

    // Calculate interest saved compared to minimum payment
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

  /// Simulate early payoff scenario
  /// Returns a map with interest savings and payoff details
  Future<Map<String, dynamic>> simulateEarlyPayoff(String cardId) async {
    // Get card
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    // Get current debt
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

    // Compare minimum payment vs full payment
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

  /// Compare multiple payment options
  /// Returns a list of simulations for different payment amounts
  Future<Map<String, dynamic>> comparePaymentOptions(
    String cardId,
    List<double> paymentAmounts,
  ) async {
    // Get card
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    // Get current debt
    final currentDebt = await _cardService.getCurrentDebt(cardId);

    if (currentDebt <= 0) {
      return {
        'currentDebt': 0.0,
        'comparisons': [],
        'message': 'Borç bulunmamaktadır',
      };
    }

    // Simulate each payment amount
    final comparisons = <Map<String, dynamic>>[];
    
    for (final amount in paymentAmounts) {
      if (amount > currentDebt) {
        continue; // Skip amounts greater than debt
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
        // Skip invalid amounts
        continue;
      }
    }

    // Sort by total cost (ascending)
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

  /// Calculate interest savings for a proposed payment
  /// Compares proposed payment with minimum payment
  Future<double> calculateInterestSavings({
    required String cardId,
    required double proposedPayment,
  }) async {
    // Get card
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    // Get current debt
    final currentDebt = await _cardService.getCurrentDebt(cardId);

    if (currentDebt <= 0 || proposedPayment <= 0) {
      return 0.0;
    }

    // Simulate minimum payment
    final minimumSimulation = await simulateMinimumPayment(cardId);
    
    // Simulate proposed payment
    final proposedSimulation = await simulatePayment(
      cardId: cardId,
      paymentAmount: proposedPayment,
    );

    // Calculate savings
    final minimumTotalCost = minimumSimulation['totalCost'] as double;
    final proposedTotalCost = proposedSimulation.totalCost;

    final savings = minimumTotalCost - proposedTotalCost;

    return savings > 0 ? savings : 0.0;
  }

  /// Get payment recommendation based on card debt and interest rate
  Future<Map<String, dynamic>> getPaymentRecommendation(String cardId) async {
    // Get card
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    // Get current debt
    final currentDebt = await _cardService.getCurrentDebt(cardId);

    if (currentDebt <= 0) {
      return {
        'recommendation': 'no_debt',
        'message': 'Borç bulunmamaktadır',
        'suggestedPayment': 0.0,
      };
    }

    // Calculate minimum payment
    final minimumPayment = max(currentDebt * 0.33, 100.0);

    // Calculate recommended payment (50% of debt to balance payoff speed and cash flow)
    final recommendedPayment = currentDebt * 0.50;

    // Simulate both scenarios
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
