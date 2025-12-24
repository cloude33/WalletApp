/// Result pattern - Success veya Failure döndüren sealed class
sealed class Result<T> {
  const Result();

  /// Success durumunda data ile birlikte yeni Result oluştur
  factory Result.success(T data) = Success<T>;

  /// Failure durumunda message ve opsiyonel exception ile Result oluştur
  factory Result.failure(String message, [Exception? exception]) = 
      Failure<T>;

  /// Result'ın success olup olmadığını kontrol et
  bool get isSuccess => this is Success<T>;

  /// Result'ın failure olup olmadığını kontrol et
  bool get isFailure => this is Failure<T>;

  /// Success ise data'yı döndür, değilse null
  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    Failure() => null,
  };

  /// Failure ise message'ı döndür, değilse null
  String? get errorOrNull => switch (this) {
    Success() => null,
    Failure(:final message) => message,
  };

  /// Success ise callback'i çalıştır
  Result<T> onSuccess(void Function(T data) callback) {
    if (this is Success<T>) {
      callback((this as Success<T>).data);
    }
    return this;
  }

  /// Failure ise callback'i çalıştır
  Result<T> onFailure(void Function(String message, Exception? exception) callback) {
    if (this is Failure<T>) {
      final failure = this as Failure<T>;
      callback(failure.message, failure.exception);
    }
    return this;
  }

  /// Map fonksiyonu - Success ise transform et
  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success(:final data) => Result.success(transform(data)),
      Failure(:final message, :final exception) => 
          Result.failure(message, exception),
    };
  }

  /// FlatMap fonksiyonu - Success ise transform et ve flatten yap
  Result<R> flatMap<R>(Result<R> Function(T data) transform) {
    return switch (this) {
      Success(:final data) => transform(data),
      Failure(:final message, :final exception) => 
          Result.failure(message, exception),
    };
  }

  /// Fold fonksiyonu - Success ve Failure için farklı handler'lar
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(String message, Exception? exception) onFailure,
  }) {
    return switch (this) {
      Success(:final data) => onSuccess(data),
      Failure(:final message, :final exception) => onFailure(message, exception),
    };
  }
}

/// Success durumu - veri içerir
final class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  String toString() => 'Success(data: $data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;
}

/// Failure durumu - hata mesajı ve opsiyonel exception içerir
final class Failure<T> extends Result<T> {
  final String message;
  final Exception? exception;

  const Failure(this.message, [this.exception]);

  @override
  String toString() => 'Failure(message: $message, exception: $exception)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          exception == other.exception;

  @override
  int get hashCode => message.hashCode ^ exception.hashCode;
}

/// Result pattern için extension metodları
extension ResultExtensions<T> on Result<T> {
  /// Success ise data'yı döndür, Failure ise exception fırlat
  T getOrThrow() {
    return switch (this) {
      Success(:final data) => data,
      Failure(:final message, :final exception) => 
          throw exception ?? Exception(message),
    };
  }

  /// Success ise data'yı döndür, Failure ise default value
  T getOrDefault(T defaultValue) {
    return switch (this) {
      Success(:final data) => data,
      Failure() => defaultValue,
    };
  }

  /// Success ise data'yı döndür, Failure ise callback'ten değer al
  T getOrElse(T Function(String message, Exception? exception) orElse) {
    return switch (this) {
      Success(:final data) => data,
      Failure(:final message, :final exception) => orElse(message, exception),
    };
  }
}

/// Future<Result<T>> için extension metodları
extension FutureResultExtensions<T> on Future<Result<T>> {
  /// Async onSuccess
  Future<Result<T>> onSuccess(Future<void> Function(T data) callback) async {
    final result = await this;
    if (result is Success<T>) {
      await callback(result.data);
    }
    return result;
  }

  /// Async onFailure
  Future<Result<T>> onFailure(
    Future<void> Function(String message, Exception? exception) callback,
  ) async {
    final result = await this;
    if (result is Failure<T>) {
      await callback(result.message, result.exception);
    }
    return result;
  }

  /// Async map
  Future<Result<R>> map<R>(R Function(T data) transform) async {
    final result = await this;
    return result.map(transform);
  }

  /// Async flatMap
  Future<Result<R>> flatMap<R>(
    Future<Result<R>> Function(T data) transform,
  ) async {
    final result = await this;
    return switch (result) {
      Success(:final data) => await transform(data),
      Failure(:final message, :final exception) => 
          Result.failure(message, exception),
    };
  }
}
