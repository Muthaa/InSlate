import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/core/presentation/financial_presentation.dart';

void main() {
  test(
    'integer KES formatting matches existing positive, zero and negative money style',
    () {
      for (final minor in [0, 1, -1, 100, -100, 123456789, -123456789]) {
        expect(formatKesMinor(BigInt.from(minor)), formatMoney(minor / 100));
      }
    },
  );
  test(
    'integer KES formatting retains digits beyond floating-point precision',
    () {
      expect(
        formatKesMinor(BigInt.parse('9223372036854775807')),
        'KSh 92,233,720,368,547,758.07',
      );
    },
  );
}
