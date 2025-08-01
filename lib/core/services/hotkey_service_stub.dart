// Stub file for non-web platforms
class Event {}

class KeyboardEvent extends Event {
  bool get ctrlKey => false;
  bool get shiftKey => false;
  bool get altKey => false;
  bool get metaKey => false;
  String get code => '';
  void preventDefault() {}
}

class Document {
  void addEventListener(String type, Function(Event) handler) {}
}

class Window {
  void open(String url, String target) {}
}

final document = Document();
final window = Window();
