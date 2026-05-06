import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/core/config/env.dart';

void main() {
  test('env constants are accessible', () {
    expect(Env.supabaseUrl, isA<String>());
    expect(Env.supabaseAnonKey, isA<String>());
  });
}
