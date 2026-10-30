import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/core/utils/learning_language.dart';

void main() {
  test('learning screens are in English except the Kiswahili subject', () {
    expect(learningLanguage(), 'en');
    expect(learningLanguage('3'), 'en', reason: 'Chemistry');
    expect(learningLanguage('6'), 'en', reason: 'English Language');
    expect(learningLanguage('5'), 'sw', reason: 'Kiswahili by route id');
    expect(learningLanguage('fb4e29c8-d1ff-4841-b0db-e3a2410a8d67'), 'sw', reason: 'Kiswahili by database id');
  });
}
