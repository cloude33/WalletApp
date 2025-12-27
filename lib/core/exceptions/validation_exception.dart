/// Validasyon hataları için özel exception sınıfı
class ValidationException implements Exception {
  final String message;
  final String? field;
  final dynamic value;

  ValidationException(
    this.message, {
    this.field,
    this.value,
  });

  @override
  String toString() {
    if (field != null) {
      return 'ValidationException: $message (field: $field, value: $value)';
    }
    return 'ValidationException: $message';
  }
}
