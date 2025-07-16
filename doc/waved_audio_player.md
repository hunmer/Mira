# waved_audio_player
<div align="center">
  <img src="https://github.com/Ahmed2000Github/waved_audio_player/blob/main/screenshots/logo.png?raw=true" alt="logo" width="200"/>
</div>
<p align="center">
  <img src="https://img.shields.io/badge/version-1.3.0-blue" alt="Version 1.3.0"/>
  <a href="https://pub.dev/packages/waved_audio_player">
    <img src="https://img.shields.io/pub/v/waved_audio_player.svg" alt="Pub Version 1.3.0">
  </a>
</p>
A Flutter package for displaying audio waveforms and controlling audio playback with a customizable user interface. Perfect for applications that require audio visualization, such as music players, audio editors, and more.

## Features
- Visualize audio waveforms from various sources (assets, URLs, and device files).
- Play, pause, and seek audio playback.
- Customizable appearance with adjustable colors, sizes, and spacing.
- Easy integration with existing Flutter applications.
  
<img src="https://github.com/Ahmed2000Github/waved_audio_player/blob/main/screenshots/waved_audio_player.gif?raw=true" alt="Your GIF Description" width="300"/>

## Getting started
### Prerequisites
- Flutter SDK (version >=1.17.0)
- Dart SDK (version '>=3.0.0 <4.0.0')

To use the `waved_audio_player` package, add it to your `pubspec.yaml` file:

```yaml
dependencies:
  waved_audio_player: ^1.2.1
  audioplayers: ^6.1.0 
```
### Installation
Run the following command in your terminal to install the package:
```bash
flutter pub get
```
## Usage
Here's a simple example of how to use the `waved_audio_player` in your Flutter app:

```dart
import 'package:flutter/material.dart';
import 'package:waved_audio_player/waved_audio_player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Waved Audio Player Example'),
        ),
        body: Center(
          child: WavedAudioPlayer(
            source: AssetSource('assets/sample.mp3'),
            iconColor: Colors.red,
            iconBackgoundColor: Colors.blue,
            playedColor: Colors.green,
            unplayedColor: Colors.grey,
            waveWidth: 100,
            barWidth: 2,
            buttonSize: 40,
            showTiming: true,
            onError: (error) {
              print('Error occurred: $error.message');
            },
          ),
        ),
      ),
    );
  }
}
```
## Additional information
For more information about the `waved_audio_player` package, visit the official documentation on [pub.dev](https://pub.dev/packages/waved_audio_player).

### Contributing
Contributions are welcome! Please feel free to submit a pull request or open an issue if you find a bug or have a feature request.

### Issues
If you encounter any problems or have questions about the package, please open an issue on [GitHub](https://github.com/Ahmed2000Github/waved_audio_player/issues).

### Author
This package is maintained by [Ahmed EL RHAOUTI](https://github.com/Ahmed2000Github).
