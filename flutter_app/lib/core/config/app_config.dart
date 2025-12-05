/// Application Configuration
class AppConfig {
  // Camera Settings
  static const int cameraFps = 10;
  static const double keyframeThreshold = 0.85; // SSIM threshold

  // Audio Settings
  static const int audioSampleRate = 16000;
  static const double vadThreshold = 0.5;
  static const double speakerIdThreshold = 0.75;

  // Memory & Summarization
  static const int summaryIntervalSeconds = 180; // 3 minutes
  static const int maxMemoryChunks = 100;
  static const int contextWindowTokens = 8000;

  // LLM Settings
  static const String llmModel = 'gpt-4';
  static const int llmMaxTokens = 500;
  static const double llmTemperature = 0.7;

  // API Configuration
  static const String apiBaseUrl = 'https://api.openai.com/v1';
  static String apiKey = ''; // Set in settings

  // Performance
  static const int maxKeyframesPerHour = 40;
  static const int processingQueueSize = 10;

  // UI Settings
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackbarDuration = Duration(seconds: 3);
}
