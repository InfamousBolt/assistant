"""
Configuration file for the Real-Time Multimodal AI Assistant
"""

# Camera Settings
CAMERA_FPS = 10
CAMERA_RESOLUTION = (640, 480)
KEYFRAME_THRESHOLD = 0.85  # SSIM threshold (lower = more sensitive to changes)
OCR_CONFIDENCE_THRESHOLD = 0.5

# Audio Settings
AUDIO_SAMPLE_RATE = 16000
AUDIO_CHUNK_SIZE = 1024
VAD_THRESHOLD = 0.5
SPEAKER_ID_THRESHOLD = 0.75  # Cosine similarity threshold for user voice filtering

# Memory & Summarization
SUMMARY_INTERVAL_SECONDS = 180  # 3 minutes
MAX_MEMORY_CHUNKS = 100
CONTEXT_WINDOW_TOKENS = 8000

# LLM Settings
LLM_MODEL = "gpt-5"
LLM_MAX_TOKENS = 500
LLM_TEMPERATURE = 0.7

# Performance
MAX_KEYFRAMES_PER_HOUR = 40
PROCESSING_QUEUE_SIZE = 10

# Question Detection Patterns
QUESTION_PATTERNS = [
    r'\?$',
    r'^(what|who|where|when|why|how|can|could|would|is|are|do|does)',
    r'(tell me|explain|show me|help)',
]

# Paths
VOICEPRINT_PATH = "data/user_voiceprint.npy"
MEMORY_DB_PATH = "data/memory.db"
LOGS_PATH = "logs/"
