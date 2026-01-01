import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  test('Hive encryption test', () async {
    final testPath = 'test_hive_iso_${DateTime.now().millisecondsSinceEpoch}';
    await Directory(testPath).create(recursive: true);
    Hive.init(testPath);

    final key = List<int>.generate(32, (i) => i);
    final cipher = HiveAesCipher(key);

    print('Opening box...');
    final box = await Hive.openBox('test_box', encryptionCipher: cipher);
    print('Box opened.');

    print('Putting value...');
    await box.put('key', 'value');
    print('Value put.');

    print('Getting value...');
    final value = box.get('key');
    print('Value got: $value');

    expect(value, 'value');

    await box.close();
    await Directory(testPath).delete(recursive: true);
  });
}
