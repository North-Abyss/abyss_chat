import 'dart:js_interop';

@JS('Notification')
external JSAny? get _notificationGlobal;

@JS('Notification.permission')
external JSString? get _permission;

@JS('Notification.requestPermission')
external JSPromise<JSAny?> _requestPermission();

@JS('Notification')
extension type WebNotification._(JSObject _) implements JSObject {
  external factory WebNotification(String title, [JSObject options]);
}

void showWebNotification(String title, String body) {
  if (_notificationGlobal == null) return;
  
  final perm = _permission?.toDart;
  if (perm == 'granted') {
    WebNotification(title, {'body': body}.jsify() as JSObject);
  } else if (perm != 'denied') {
    _requestPermission().toDart.then((newPerm) {
      if (newPerm != null && (newPerm as JSString).toDart == 'granted') {
        WebNotification(title, {'body': body}.jsify() as JSObject);
      }
    });
  }
}
