import 'dart:math';

int generateTenDigitRandomNumber() {
  final random = Random();
  
  final firstDigit = random.nextInt(9) + 1;
  final remainingDigits = List.generate(9, (_) => random.nextInt(10));
  int result = firstDigit;
  for (var digit in remainingDigits) {
    result = result * 10 + digit;
  }
  
  return result;
}