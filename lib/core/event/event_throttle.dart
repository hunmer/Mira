import 'package:mira/core/event/event.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';

class EventThrottle {
  final _streamController = StreamController<EventArgs>();
  late final Duration _duration;
  EventThrottle({Duration? duration})
    : _duration = duration ?? const Duration(milliseconds: 500);

  // 输出流经过 debounceTime 节流
  Stream<EventArgs> get stream =>
      _streamController.stream.throttleTime(_duration);

  void onCall(EventArgs event) {
    _streamController.sink.add(event);
  }

  void dispose() {
    _streamController.close();
  }
}
