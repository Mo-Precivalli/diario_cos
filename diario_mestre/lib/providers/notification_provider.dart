import 'package:flutter/foundation.dart';

class NotificationMessage {
  final String message;
  final bool isError;
  final DateTime timestamp;

  NotificationMessage({required this.message, this.isError = false})
    : timestamp = DateTime.now();
}

class NotificationProvider extends ChangeNotifier {
  NotificationMessage? _latestMessage;

  NotificationMessage? get latestMessage => _latestMessage;

  void notify(String message, {bool isError = false}) {
    _latestMessage = NotificationMessage(message: message, isError: isError);
    notifyListeners();
  }

  void notifyError(String message) => notify(message, isError: true);
  void notifySuccess(String message) => notify(message, isError: false);

  // Clear after consuming
  void clear() {
    _latestMessage = null;
    // No notify listeners usually needed if consuming instantly, or yes to reset state?
    // We don't notify here to avoid rebuild loop if consumed in build/listener.
  }
}
