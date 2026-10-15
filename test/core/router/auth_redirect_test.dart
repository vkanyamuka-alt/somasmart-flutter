import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/core/router/app_router.dart';

void main() {
  group('authRedirect (route guard)', () {
    test('public routes stay reachable when signed out', () {
      for (final route in [
        '/splash',
        '/welcome',
        '/login',
        '/signup',
        '/forgot-password',
        '/contact-support',
      ]) {
        expect(authRedirect(location: route, isSignedIn: false), isNull, reason: route);
      }
    });

    test('every other route sends signed-out users to /login', () {
      for (final route in [
        '/home',
        '/shop',
        '/payment',
        '/subscription',
        '/account',
        '/ask-me',
        '/notes/abc',
        '/quiz/results/1',
        '/practical/simulation/titration',
        '/verify-otp',
      ]) {
        expect(authRedirect(location: route, isSignedIn: false), '/login', reason: route);
      }
    });

    test('signed-in users are never redirected', () {
      for (final route in ['/home', '/payment', '/login', '/splash']) {
        expect(authRedirect(location: route, isSignedIn: true), isNull, reason: route);
      }
    });

    test('/verify-otp is not a public route', () {
      expect(publicRoutes.contains('/verify-otp'), isFalse);
    });
  });
}
