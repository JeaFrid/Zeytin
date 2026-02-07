import 'dart:math';

int generateTenDigitRandomNumber() {
  final random = Random();
  int min = 1000000000;
  int max = 9999999999;
  
  int result = min + random.nextInt(max - min);
  return result;
}