# 📱 AI Assistant - Flutter App

Real-Time Multimodal AI Assistant with Camera, Audio, and GPT Integration.

## ✨ Features

- **📹 Live Camera Feed** - Real-time video processing with keyframe detection
- **🎤 Voice Input** - Speech-to-text for asking questions
- **👁️ OCR** - Automatic text recognition from camera feed
- **💬 Chat Interface** - Natural conversation with AI
- **🧠 Context Memory** - Maintains conversation history and summaries
- **⚙️ Customizable** - Configurable settings for API keys and preferences

## 🏗️ Architecture

```
flutter_app/
├── lib/
│   ├── core/
│   │   ├── config/          # App configuration
│   │   ├── models/          # Data models
│   │   ├── services/        # Core services
│   │   └── utils/           # Utilities
│   ├── features/
│   │   ├── camera/          # Camera & OCR feature
│   │   ├── chat/            # Chat interface
│   │   └── settings/        # Settings screen
│   ├── shared/
│   │   ├── widgets/         # Shared widgets
│   │   └── constants/       # Constants
│   └── main.dart            # App entry point
└── pubspec.yaml             # Dependencies
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK >=3.0.0
- Dart SDK >=3.0.0
- iOS: Xcode 14+, iOS 14+
- Android: Android Studio, SDK 21+

### Installation

1. **Install Flutter dependencies**
   ```bash
   cd flutter_app
   flutter pub get
   ```

2. **Configure Permissions**

   **iOS** (`ios/Runner/Info.plist`):
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>Camera access required for visual context</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>Microphone access required for voice input</string>
   <key>NSSpeechRecognitionUsageDescription</key>
   <string>Speech recognition required for questions</string>
   ```

   **Android** (`android/app/src/main/AndroidManifest.xml`):
   ```xml
   <uses-permission android:name="android.permission.CAMERA" />
   <uses-permission android:name="android.permission.RECORD_AUDIO" />
   <uses-permission android:name="android.permission.INTERNET" />
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 📋 Usage

### 1. Camera Screen
- **View live camera feed**
- **See keyframe detection** in real-time
- **OCR text extraction** from visible code/text
- **Statistics** showing frames processed

### 2. Chat Screen
- **Type questions** or **use voice input**
- **AI responses** with context from camera
- **Conversation history** maintained
- **Confidence scores** for each answer

### 3. Settings Screen
- **API Key configuration** for OpenAI
- **Toggle Mock/Real LLM** mode
- **View memory statistics**
- **Clear conversation** history

## 🎮 Controls

### Camera Screen
- Live preview with overlay
- Automatic keyframe detection
- OCR text display when detected

### Chat Screen
- **Mic button** - Start/stop voice input
- **Text input** - Type questions manually
- **Clear button** - Reset conversation
- **Auto-scroll** to latest messages

## ⚙️ Configuration

Edit `lib/core/config/app_config.dart`:

```dart
class AppConfig {
  // Camera Settings
  static const int cameraFps = 10;
  static const double keyframeThreshold = 0.85;

  // Audio Settings
  static const int audioSampleRate = 16000;

  // LLM Settings
  static const String llmModel = 'gpt-4';
  static const int llmMaxTokens = 500;

  // Memory Settings
  static const int summaryIntervalSeconds = 180; // 3 minutes
  static const int maxMemoryChunks = 100;
}
```

## 🔑 API Key Setup

1. Get an OpenAI API key from https://platform.openai.com
2. Open **Settings** in the app
3. Enter your API key
4. Toggle "Use Mock LLM" to OFF
5. Save settings

**Note:** Mock mode works without an API key for testing!

## 📦 Dependencies

### Core
- `camera` - Camera access
- `google_mlkit_text_recognition` - OCR
- `record` & `speech_to_text` - Audio processing
- `provider` - State management

### UI
- `google_fonts` - Typography
- `flutter_animate` - Animations
- `lottie` - Advanced animations

### Backend
- `dio` - HTTP client for API calls
- `shared_preferences` - Local storage

## 🏃 Running on Devices

### iOS Simulator
```bash
flutter run -d "iPhone 15 Pro"
```

### Android Emulator
```bash
flutter run -d "emulator-5554"
```

### Physical Device
```bash
flutter devices  # List connected devices
flutter run -d <device-id>
```

## 🧪 Testing

### Run all tests
```bash
flutter test
```

### Widget tests
```bash
flutter test test/widgets/
```

### Integration tests
```bash
flutter test integration_test/
```

## 🐛 Troubleshooting

### Camera not working
- Check permissions in Settings app
- Verify `Info.plist` / `AndroidManifest.xml` configuration
- Restart the app

### Microphone not working
- Grant microphone permissions
- Check device audio settings
- Verify speech-to-text initialization

### OCR not detecting text
- Ensure good lighting
- Show text clearly to camera
- Text should be high contrast

### API errors
- Verify API key is correct
- Check internet connection
- Ensure sufficient API credits
- Use Mock mode for testing

## 📱 Platform-Specific Notes

### iOS
- Requires iOS 14.0+
- Camera permission must be granted
- Works on simulator (limited camera)

### Android
- Requires API level 21+ (Android 5.0)
- Camera permission must be granted
- Google Play Services required for ML Kit

## 🔮 Future Enhancements

- [ ] Real-time video streaming to backend
- [ ] Speaker diarization (ECAPA-TDNN)
- [ ] Multi-language support
- [ ] Offline mode with local models
- [ ] Screen recording for playback
- [ ] Export conversation history
- [ ] Custom voice wake words

## 📄 License

See main project LICENSE

## 🤝 Contributing

Contributions welcome! See main project README for guidelines.

## 📞 Support

For issues or questions:
- Check this README
- See main project documentation
- Open an issue on GitHub

---

Built with ❤️ using Flutter
