// Default smoke test placeholder.
// Karena app utama butuh Firebase, smoke test hanya verifikasi konstanta.
import 'package:flutter_test/flutter_test.dart';
import 'package:resto_queue/core/constants.dart';

void main() {
  test('App constants sane', () {
    expect(AppConstants.appName, isNotEmpty);
    expect(QueueStatus.values, contains(QueueStatus.waiting));
  });
}
