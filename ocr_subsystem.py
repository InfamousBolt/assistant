"""
OCR Subsystem: Extract text from frames
"""

import cv2
import numpy as np
from typing import List, Dict, Optional
try:
    import pytesseract
    TESSERACT_AVAILABLE = True
except ImportError:
    TESSERACT_AVAILABLE = False
    print("Warning: pytesseract not available, using mock OCR")

import config


class OCRSubsystem:
    """Handles text extraction from images"""

    def __init__(self):
        self.previous_text = ""
        self.text_changes = 0

    def preprocess_for_ocr(self, frame: np.ndarray) -> np.ndarray:
        """Preprocess frame to improve OCR accuracy"""
        # Convert to grayscale
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

        # Apply thresholding to get binary image
        _, binary = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

        # Denoise
        denoised = cv2.fastNlMeansDenoising(binary, None, 10, 7, 21)

        return denoised

    def extract_text(self, frame: np.ndarray) -> Dict[str, any]:
        """
        Extract text from frame using OCR
        Returns: dict with 'text', 'confidence', 'changed'
        """
        preprocessed = self.preprocess_for_ocr(frame)

        if TESSERACT_AVAILABLE:
            try:
                # Extract text with confidence
                data = pytesseract.image_to_data(preprocessed, output_type=pytesseract.Output.DICT)

                # Filter by confidence threshold
                text_parts = []
                confidences = []

                for i, conf in enumerate(data['conf']):
                    if conf > config.OCR_CONFIDENCE_THRESHOLD * 100:
                        text = data['text'][i].strip()
                        if text:
                            text_parts.append(text)
                            confidences.append(conf)

                extracted_text = ' '.join(text_parts)
                avg_confidence = np.mean(confidences) / 100 if confidences else 0.0

            except Exception as e:
                print(f"OCR error: {e}")
                extracted_text = ""
                avg_confidence = 0.0
        else:
            # Mock OCR for testing
            extracted_text = self._mock_ocr(frame)
            avg_confidence = 0.95

        # Check if text changed significantly
        changed = self._text_changed(extracted_text)

        return {
            'text': extracted_text,
            'confidence': avg_confidence,
            'changed': changed,
            'word_count': len(extracted_text.split())
        }

    def _mock_ocr(self, frame: np.ndarray) -> str:
        """Mock OCR for testing without tesseract"""
        # Simulate detecting different text based on frame brightness
        brightness = np.mean(frame)

        if brightness > 150:
            return "def calculate_sum(a, b): return a + b"
        elif brightness > 100:
            return "Error: NullPointerException at line 42"
        else:
            return "Console output: Processing complete"

    def _text_changed(self, new_text: str) -> bool:
        """Check if text changed significantly from previous frame"""
        if not self.previous_text:
            self.previous_text = new_text
            return bool(new_text.strip())

        # Simple text difference check
        similarity = len(set(new_text.split()) & set(self.previous_text.split())) / \
                    max(len(set(new_text.split())), 1)

        changed = similarity < 0.7  # If less than 70% similar, consider it changed

        if changed:
            self.previous_text = new_text
            self.text_changes += 1
            if new_text.strip():
                print(f"📝 Text changed: {new_text[:50]}...")

        return changed

    def get_stats(self) -> dict:
        """Get OCR statistics"""
        return {
            'text_changes': self.text_changes,
            'last_text_length': len(self.previous_text)
        }


if __name__ == "__main__":
    # Test the OCR subsystem
    import camera_subsystem

    camera = camera_subsystem.CameraSubsystem()
    ocr = OCRSubsystem()

    if not camera.start():
        print("Failed to start camera")
        exit(1)

    print("Press 'q' to quit")
    print("Show text/code to the camera to test OCR")

    try:
        while True:
            result = camera.get_frame_with_keyframe_detection()
            if result is None:
                break

            frame, is_keyframe = result

            # Run OCR on keyframes only
            if is_keyframe:
                ocr_result = ocr.extract_text(frame)
                if ocr_result['text']:
                    print(f"\n📄 OCR Result (confidence: {ocr_result['confidence']:.2f}):")
                    print(f"   {ocr_result['text'][:100]}")

            # Display frame
            cv2.imshow('OCR Test', frame)

            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

    finally:
        camera.stop()
        cv2.destroyAllWindows()
        print("\nOCR Stats:", ocr.get_stats())
