"""
Audio Subsystem: Voice Activity Detection, Speaker ID, Speech-to-Text
"""

import numpy as np
import time
from typing import Optional, Dict, List
import re
try:
    import pyaudio
    import webrtcvad
    AUDIO_AVAILABLE = True
except ImportError:
    AUDIO_AVAILABLE = False
    print("Warning: pyaudio/webrtcvad not available, using mock audio")

import config


class AudioSubsystem:
    """Handles audio capture, VAD, speaker identification, and STT"""

    def __init__(self):
        self.audio = None
        self.stream = None
        self.vad = None
        self.user_voiceprint = None
        self.is_recording = False
        self.audio_buffer = []
        self.speech_count = 0
        self.non_user_speech_count = 0

        # Initialize VAD if available
        if AUDIO_AVAILABLE:
            try:
                self.vad = webrtcvad.Vad(2)  # Aggressiveness level 0-3
            except:
                print("Warning: Could not initialize WebRTC VAD")

    def start(self) -> bool:
        """Initialize audio capture"""
        if not AUDIO_AVAILABLE:
            print("Audio system running in MOCK mode")
            self.is_recording = True
            return True

        try:
            self.audio = pyaudio.PyAudio()
            self.stream = self.audio.open(
                format=pyaudio.paInt16,
                channels=1,
                rate=config.AUDIO_SAMPLE_RATE,
                input=True,
                frames_per_buffer=config.AUDIO_CHUNK_SIZE
            )
            self.is_recording = True
            print(f"Audio started: {config.AUDIO_SAMPLE_RATE} Hz")
            return True
        except Exception as e:
            print(f"Error starting audio: {e}")
            return False

    def stop(self):
        """Stop audio capture and release resources"""
        self.is_recording = False

        if self.stream:
            self.stream.stop_stream()
            self.stream.close()

        if self.audio:
            self.audio.terminate()

        print("Audio stopped")

    def load_user_voiceprint(self, voiceprint_path: str) -> bool:
        """Load user's voice embedding for filtering"""
        try:
            self.user_voiceprint = np.load(voiceprint_path)
            print(f"Loaded user voiceprint: {voiceprint_path}")
            return True
        except:
            print("No user voiceprint found, creating mock voiceprint")
            # Create mock voiceprint (random embedding)
            self.user_voiceprint = np.random.randn(192)  # ECAPA-TDNN typical size
            return True

    def capture_audio_chunk(self) -> Optional[bytes]:
        """Capture a chunk of audio data"""
        if not self.is_recording:
            return None

        if not AUDIO_AVAILABLE:
            # Mock audio data
            time.sleep(0.1)
            return np.random.randint(-1000, 1000, config.AUDIO_CHUNK_SIZE, dtype=np.int16).tobytes()

        try:
            data = self.stream.read(config.AUDIO_CHUNK_SIZE, exception_on_overflow=False)
            return data
        except Exception as e:
            print(f"Error capturing audio: {e}")
            return None

    def detect_voice_activity(self, audio_chunk: bytes) -> bool:
        """
        Detect if audio chunk contains speech using VAD
        Returns: True if speech detected, False otherwise
        """
        if not AUDIO_AVAILABLE or not self.vad:
            # Mock VAD: randomly detect speech 20% of the time
            return np.random.random() < 0.2

        try:
            # WebRTC VAD requires specific frame sizes (10, 20, or 30 ms)
            # For 16kHz: 10ms = 160 samples, 20ms = 320 samples, 30ms = 480 samples
            frame_duration = 30  # ms
            sample_count = int(config.AUDIO_SAMPLE_RATE * frame_duration / 1000)

            # Ensure we have enough data
            if len(audio_chunk) < sample_count * 2:  # 2 bytes per sample
                return False

            # Take only the required frame size
            frame = audio_chunk[:sample_count * 2]

            is_speech = self.vad.is_speech(frame, config.AUDIO_SAMPLE_RATE)
            if is_speech:
                self.speech_count += 1
            return is_speech

        except Exception as e:
            # Fallback to energy-based VAD
            audio_array = np.frombuffer(audio_chunk, dtype=np.int16)
            energy = np.sqrt(np.mean(audio_array.astype(float) ** 2))
            return energy > 500  # Threshold

    def extract_speaker_embedding(self, audio_chunk: bytes) -> np.ndarray:
        """
        Extract speaker embedding using ECAPA-TDNN (mocked)
        In production, would use actual model
        """
        # Mock embedding: random vector
        embedding = np.random.randn(192)
        return embedding / np.linalg.norm(embedding)  # Normalize

    def is_user_speaking(self, audio_chunk: bytes) -> bool:
        """
        Check if the speaker is the user (to filter out)
        Returns: True if user is speaking, False if someone else
        """
        if self.user_voiceprint is None:
            # No voiceprint, assume it's not the user
            return False

        # Extract embedding from current audio
        current_embedding = self.extract_speaker_embedding(audio_chunk)

        # Calculate cosine similarity
        similarity = np.dot(current_embedding, self.user_voiceprint)

        # If similarity is high, it's the user
        is_user = similarity > config.SPEAKER_ID_THRESHOLD

        if not is_user:
            self.non_user_speech_count += 1

        return is_user

    def transcribe_speech(self, audio_chunk: bytes) -> Dict[str, any]:
        """
        Transcribe speech to text using Whisper (mocked)
        In production, would use actual Whisper model
        Returns: dict with 'text', 'is_question', 'confidence'
        """
        # Mock transcription: return various sample questions/statements
        mock_transcriptions = [
            "What does this function do?",
            "Can you explain this error message?",
            "How do I fix this bug?",
            "Why is this not working?",
            "Show me how to use this API",
            "What's the purpose of this code?",
            "This looks good",
            "I see what you mean",
            "That makes sense now"
        ]

        # Randomly select a transcription (favor questions)
        text = np.random.choice(mock_transcriptions)
        confidence = np.random.uniform(0.85, 0.98)

        # Detect if it's a question
        is_question = self._is_question(text)

        return {
            'text': text,
            'is_question': is_question,
            'confidence': confidence,
            'timestamp': time.time()
        }

    def _is_question(self, text: str) -> bool:
        """Detect if text is a question using patterns"""
        text_lower = text.lower().strip()

        # Check for question mark
        if text_lower.endswith('?'):
            return True

        # Check for question patterns
        for pattern in config.QUESTION_PATTERNS:
            if re.search(pattern, text_lower, re.IGNORECASE):
                return True

        return False

    def process_audio_stream(self) -> Optional[Dict[str, any]]:
        """
        Process audio stream: VAD -> Speaker ID -> STT
        Returns: transcription dict if non-user question detected, None otherwise
        """
        audio_chunk = self.capture_audio_chunk()
        if audio_chunk is None:
            return None

        # Step 1: Voice Activity Detection
        has_speech = self.detect_voice_activity(audio_chunk)
        if not has_speech:
            return None

        # Step 2: Speaker Identification
        is_user = self.is_user_speaking(audio_chunk)
        if is_user:
            # Filter out user's voice
            return None

        # Step 3: Speech-to-Text
        transcription = self.transcribe_speech(audio_chunk)

        # Only return if it's a question
        if transcription['is_question']:
            print(f"🎤 Non-user question detected: \"{transcription['text']}\"")
            return transcription

        return None

    def get_stats(self) -> dict:
        """Get audio subsystem statistics"""
        return {
            'total_speech_detected': self.speech_count,
            'non_user_speech': self.non_user_speech_count,
            'user_speech_filtered': self.speech_count - self.non_user_speech_count
        }


if __name__ == "__main__":
    # Test the audio subsystem
    audio = AudioSubsystem()

    # Load or create user voiceprint
    audio.load_user_voiceprint(config.VOICEPRINT_PATH)

    if not audio.start():
        print("Failed to start audio")
        exit(1)

    print("Listening for non-user questions...")
    print("Press Ctrl+C to stop")

    try:
        question_count = 0
        while True:
            result = audio.process_audio_stream()

            if result:
                question_count += 1
                print(f"\n[Question #{question_count}]")
                print(f"  Text: {result['text']}")
                print(f"  Confidence: {result['confidence']:.2%}")
                print(f"  Timestamp: {time.strftime('%H:%M:%S', time.localtime(result['timestamp']))}")

            time.sleep(0.01)  # Small delay to prevent CPU overuse

    except KeyboardInterrupt:
        print("\n\nStopping...")

    finally:
        audio.stop()
        print("\nAudio Stats:", audio.get_stats())
