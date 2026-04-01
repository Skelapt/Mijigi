import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native Android clipboard listener.
/// Fires immediately when clipboard content changes.
class ClipboardService {
  static const _channel = MethodChannel('com.mijigi/clipboard');
  static const _eventChannel = EventChannel('com.mijigi/clipboard/events');

  Stream<String>? _clipStream;

  /// Stream of clipboard text changes - fires IMMEDIATELY on copy
  Stream<String> get onClipboardChanged {
    _clipStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => event as String)
        .distinct();
    return _clipStream!;
  }

  /// Read current clipboard text via native channel
  Future<String?> getClipboardText() async {
    try {
      final text = await _channel.invokeMethod<String>('getClipboard');
      return text;
    } catch (e) {
      debugPrint('[Mijigi] Native clipboard read failed: $e');
      // Fallback to Flutter clipboard
      try {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        return data?.text;
      } catch (_) {
        return null;
      }
    }
  }
}
