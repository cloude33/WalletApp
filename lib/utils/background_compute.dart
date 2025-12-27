import 'dart:async';
import 'package:flutter/foundation.dart';
typedef ProgressCallback = void Function(double progress);
class BackgroundCompute {
  static Future<R> run<M, R>(
    ComputeCallback<M, R> computation,
    M message, {
    String? debugLabel,
  }) async {
    try {
      return await compute(
        computation,
        message,
        debugLabel: debugLabel,
      );
    } catch (e) {
      throw BackgroundComputeException(
        'Background computation failed: $e',
        originalError: e,
      );
    }
  }
  static Future<R> runWithProgress<M, R>(
    ComputeCallback<M, R> computation,
    M message, {
    ProgressCallback? onProgress,
    String? debugLabel,
  }) async {
    try {
      onProgress?.call(0.0);
      
      final result = await compute(
        computation,
        message,
        debugLabel: debugLabel,
      );
      onProgress?.call(1.0);
      
      return result;
    } catch (e) {
      throw BackgroundComputeException(
        'Background computation with progress failed: $e',
        originalError: e,
      );
    }
  }
  static bool get isAvailable {
    return !kIsWeb;
  }
  static Future<R> runIfAvailable<M, R>(
    ComputeCallback<M, R> computation,
    M message, {
    String? debugLabel,
  }) async {
    if (isAvailable) {
      return run(computation, message, debugLabel: debugLabel);
    } else {
      return computation(message);
    }
  }
}
class BackgroundComputeException implements Exception {
  final String message;
  final dynamic originalError;

  BackgroundComputeException(this.message, {this.originalError});

  @override
  String toString() => 'BackgroundComputeException: $message';
}
abstract class ComputationInput {}
abstract class ComputationResult {}
