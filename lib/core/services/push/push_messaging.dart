import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Whether Android lets SomaSmart show notifications.
enum PushPermission { granted, denied, notDetermined }

/// A push message, reduced to what the app uses.
class PushMessage {
  final String? title;
  final String? body;
  final Map<String, String> data;

  const PushMessage({this.title, this.body, this.data = const {}});

  factory PushMessage.fromRemote(RemoteMessage m) => PushMessage(
        title: m.notification?.title,
        body: m.notification?.body,
        data: m.data.map((k, v) => MapEntry(k, '$v')),
      );
}

/// Firebase Cloud Messaging behind a small interface, so the logic around it
/// can be tested without Firebase.
abstract class PushMessaging {
  /// False when this build has no Firebase config (no google-services.json).
  Future<bool> initialize();
  Future<PushPermission> permission();
  Future<PushPermission> requestPermission();
  Future<String?> getToken();
  Future<void> deleteToken();
  Stream<String> get onTokenRefresh;
  Stream<PushMessage> get onForegroundMessage;
  Stream<PushMessage> get onMessageOpenedApp;
  Future<PushMessage?> getInitialMessage();
}

class FirebasePushMessaging implements PushMessaging {
  FirebaseMessaging get _fm => FirebaseMessaging.instance;

  static PushPermission _map(AuthorizationStatus s) => switch (s) {
        AuthorizationStatus.authorized || AuthorizationStatus.provisional => PushPermission.granted,
        AuthorizationStatus.denied || AuthorizationStatus.deniedPermanently => PushPermission.denied,
        AuthorizationStatus.notDetermined => PushPermission.notDetermined,
      };

  @override
  Future<bool> initialize() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      return true;
    } catch (e) {
      debugPrint('Push notifications off: Firebase is not configured in this build ($e)');
      return false;
    }
  }

  @override
  Future<PushPermission> permission() async => _map((await _fm.getNotificationSettings()).authorizationStatus);

  /// On Android 13+ this shows the system "Allow notifications?" dialog once.
  @override
  Future<PushPermission> requestPermission() async =>
      _map((await _fm.requestPermission(alert: true, badge: true, sound: true)).authorizationStatus);

  // Registration tokens, as the FCM HTTP v1 API's `message.token` expects.
  // firebase_messaging 17 marks them deprecated in favour of FID
  // registration (register()/onRegistered); move over once the server side
  // is documented for FIDs. Until then these are the proven path.

  @override
  // ignore: deprecated_member_use
  Future<String?> getToken() => _fm.getToken();

  @override
  // ignore: deprecated_member_use
  Future<void> deleteToken() => _fm.deleteToken();

  @override
  // ignore: deprecated_member_use
  Stream<String> get onTokenRefresh => _fm.onTokenRefresh;

  @override
  Stream<PushMessage> get onForegroundMessage => FirebaseMessaging.onMessage.map(PushMessage.fromRemote);

  @override
  Stream<PushMessage> get onMessageOpenedApp => FirebaseMessaging.onMessageOpenedApp.map(PushMessage.fromRemote);

  @override
  Future<PushMessage?> getInitialMessage() async {
    final m = await _fm.getInitialMessage();
    return m == null ? null : PushMessage.fromRemote(m);
  }
}
