import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart';

/// Web implementation of the local notifications plugin.
class WebFlutterLocalNotificationsPlugin {
  ServiceWorkerRegistration? _registration;

  Future<void> show(
    int id,
    String? title,
    String? body, {
    String? payload,
  }) async {
    if (_registration == null) {
      throw StateError(
        'FlutterLocalNotifications.show(): You must call initialize() before '
        'calling this method',
      );
    } else if (Notification.permission != 'granted') {
      throw StateError(
        'FlutterLocalNotifications.show(): You must request notifications '
        'permissions first',
      );
    } else if (_registration!.active == null) {
      throw StateError(
        'FlutterLocalNotifications.show(): There is no active service worker. '
        'Call initialize() first',
      );
    }

    await _registration!
        .showNotification(title ?? 'This is a notification')
        .toDart;
  }

  /// Initializes the plugin.
  Future<bool?> initialize() async {
    _registration =
        await window.navigator.serviceWorker.getRegistration().toDart;
    return _registration != null;
  }

  /// Requests notification permission from the browser.
  ///
  /// It is highly recommended and sometimes required that this be called only
  /// in response to a user gesture, and not automatically.
  Future<bool> requestNotificationsPermission() async {
    final JSString result = await Notification.requestPermission().toDart;
    return result.toDart == 'granted';
  }

  Future<void> cancel(int id, {String? tag}) async {
    if (_registration == null) {
      return;
    }
    final List<Notification> notifs =
        await _registration!.getDartNotifications();
    for (final Notification notification in notifs) {
      if (notification.id == id || (tag != null && tag == notification.tag)) {
        notification.close();
      }
    }
  }

  Future<void> cancelAll() async {
    if (_registration == null) {
      return;
    }
    final List<Notification> notifs =
        await _registration!.getDartNotifications();
    for (final Notification notification in notifs) {
      notification.close();
    }
  }
}

extension on Notification {
  /// Gets the ID of the notification.
  int? get id => jsonDecode(data.toString())?['id'];
}

extension on ServiceWorkerRegistration {
  Future<List<Notification>> getDartNotifications() async =>
      (await getNotifications().toDart).toDart;
}
