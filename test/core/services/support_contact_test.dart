import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/core/services/support_contact_service.dart';

void main() {
  test('builds WhatsApp, call and email links like the web', () {
    const c = SupportContact(phone: '+255712345678', email: 'help@example.co.tz');
    expect(c.whatsapp.toString(), 'https://wa.me/255712345678');
    expect(c.call.toString(), 'tel:+255712345678');
    expect(c.mail.toString(), 'mailto:help@example.co.tz');
    expect(c.displayPhone, '+255 712 345 678');
  });

  test('feedback links carry the message', () {
    const c = SupportContact(phone: '+255712345678', email: 'help@example.co.tz');
    expect(c.feedbackWhatsapp(' Hello ')!.queryParameters['text'], 'SomaSmart feedback:\nHello');
    expect(c.feedbackMail('Hello').toString(), 'mailto:help@example.co.tz?subject=SomaSmart%20feedback&body=Hello');
  });

  test('ignores numbers and emails that are not valid', () {
    const c = SupportContact(phone: '0712345678', email: 'not an email');
    expect(c.isEmpty, isTrue);
    expect(c.whatsapp, isNull);
    expect(c.feedbackMail('x'), isNull);
  });
}
