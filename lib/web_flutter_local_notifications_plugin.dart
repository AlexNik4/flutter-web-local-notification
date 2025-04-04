import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart';

/// Web implementation of the local notifications plugin.
class WebFlutterLocalNotificationsPlugin {
  ServiceWorkerRegistration? _registration;
  static Function(String?)? _onNotificationClickCallback;

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

    final jsData = ({'id': id, 'payload': payload}).jsify();
    final options = NotificationOptions(
      data: jsData,
      actions: [NotificationAction(action: 'open', title: 'Open App')].toJS,
    );

    await _registration!
        .showNotification(title ?? 'This is a notification', options)
        .toDart;
  }

  /// Initializes the plugin.
  Future<bool?> initialize({Function(String?)? onNotificationClick}) async {
    _registration =
        await window.navigator.serviceWorker.getRegistration().toDart;

    if (_registration != null) {
      _onNotificationClickCallback = onNotificationClick;

      // Check URL for notification payload on startup
      _checkInitialNotification();

      // Listen for future payloads via message channel
      _setupMessageChannel();
    }

    return _registration != null;
  }

  /// Requests notification permission from the browser.
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

  //* PRIVATE METHODS ----------------------------------------------------
  void _checkInitialNotification() {
    try {
      final uri = Uri.parse(window.location.href);
      final payload = uri.queryParameters['notification_payload'];
      if (payload != null && _onNotificationClickCallback != null) {
        // Only process if this is a new window (no referrer)
        if (document.referrer.isEmpty) {
          _onNotificationClickCallback!(payload);
        }
        window.history.replaceState(null, '', window.location.pathname);
      }
    } catch (e) {
      print('Error checking initial notification: $e');
    }
  }

  void _setupMessageChannel() {
    window.navigator.serviceWorker.addEventListener(
      'message',
      (Event event) {
        final messageEvent = event as MessageEvent;
        final jsData = messageEvent.data;
        if (jsData == null) return;

        try {
          final dynamic dartData = jsData.dartify();

          // Safely handle the Map conversion
          if (dartData is Map) {
            // Convert keys and values to String/dynamic
            final data = Map<String, dynamic>.fromEntries(
              dartData.entries.map(
                (e) => MapEntry(e.key?.toString() ?? '', e.value),
              ),
            );

            if (data['type'] == 'notificationClick') {
              final payload = data['payload']?.toString();
              if (payload != null) {
                _onNotificationClickCallback?.call(payload);
              }
            }
          }
        } catch (e) {
          print('Error processing notification click: $e');
        }
      }.toJS,
    );
  }
}

extension on Notification {
  /// Gets the ID of the notification.
  int? get id {
    try {
      final data = jsonDecode(this.data.toString());
      return data?['id'];
    } catch (e) {
      return null;
    }
  }
}

extension on ServiceWorkerRegistration {
  Future<List<Notification>> getDartNotifications() async =>
      (await getNotifications().toDart).toDart;
}
