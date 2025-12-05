"""
Camera Subsystem: Captures frames, detects keyframes using SSIM
"""

import cv2
import numpy as np
from skimage.metrics import structural_similarity as ssim
from typing import Optional, Tuple
import time
import config


class CameraSubsystem:
    """Handles camera capture and keyframe detection"""

    def __init__(self, camera_id: int = 0):
        self.camera_id = camera_id
        self.cap = None
        self.previous_frame = None
        self.frame_count = 0
        self.keyframe_count = 0
        self.last_keyframe_time = 0

    def start(self) -> bool:
        """Initialize camera capture"""
        self.cap = cv2.VideoCapture(self.camera_id)
        if not self.cap.isOpened():
            print(f"Error: Could not open camera {self.camera_id}")
            return False

        # Set resolution
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, config.CAMERA_RESOLUTION[0])
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, config.CAMERA_RESOLUTION[1])
        self.cap.set(cv2.CAP_PROP_FPS, config.CAMERA_FPS)

        print(f"Camera started: {config.CAMERA_RESOLUTION[0]}x{config.CAMERA_RESOLUTION[1]} @ {config.CAMERA_FPS} fps")
        return True

    def stop(self):
        """Release camera resources"""
        if self.cap:
            self.cap.release()
            print("Camera stopped")

    def capture_frame(self) -> Optional[np.ndarray]:
        """Capture a single frame from the camera"""
        if not self.cap or not self.cap.isOpened():
            return None

        ret, frame = self.cap.read()
        if not ret:
            return None

        self.frame_count += 1
        return frame

    def is_keyframe(self, current_frame: np.ndarray) -> Tuple[bool, float]:
        """
        Determine if current frame is a keyframe using SSIM
        Returns: (is_keyframe, similarity_score)
        """
        if self.previous_frame is None:
            self.previous_frame = current_frame
            self.keyframe_count += 1
            self.last_keyframe_time = time.time()
            return True, 0.0

        # Convert to grayscale for comparison
        gray_current = cv2.cvtColor(current_frame, cv2.COLOR_BGR2GRAY)
        gray_previous = cv2.cvtColor(self.previous_frame, cv2.COLOR_BGR2GRAY)

        # Ensure same dimensions
        if gray_current.shape != gray_previous.shape:
            gray_previous = cv2.resize(gray_previous,
                                      (gray_current.shape[1], gray_current.shape[0]))

        # Calculate SSIM
        similarity = ssim(gray_current, gray_previous)

        # If similarity is below threshold, it's a keyframe
        is_keyframe = similarity < config.KEYFRAME_THRESHOLD

        if is_keyframe:
            self.previous_frame = current_frame.copy()
            self.keyframe_count += 1
            self.last_keyframe_time = time.time()
            print(f"🔑 Keyframe detected! (SSIM: {similarity:.3f})")

        return is_keyframe, similarity

    def get_frame_with_keyframe_detection(self) -> Optional[Tuple[np.ndarray, bool]]:
        """
        Capture frame and determine if it's a keyframe
        Returns: (frame, is_keyframe) or None if capture fails
        """
        frame = self.capture_frame()
        if frame is None:
            return None

        is_keyframe, _ = self.is_keyframe(frame)
        return frame, is_keyframe

    def get_stats(self) -> dict:
        """Get camera statistics"""
        return {
            'total_frames': self.frame_count,
            'keyframes': self.keyframe_count,
            'keyframe_ratio': self.keyframe_count / max(1, self.frame_count),
            'time_since_last_keyframe': time.time() - self.last_keyframe_time
        }


if __name__ == "__main__":
    # Test the camera subsystem
    camera = CameraSubsystem()

    if not camera.start():
        print("Failed to start camera")
        exit(1)

    print("Press 'q' to quit")

    try:
        while True:
            result = camera.get_frame_with_keyframe_detection()
            if result is None:
                break

            frame, is_keyframe = result

            # Display frame with keyframe indicator
            if is_keyframe:
                cv2.rectangle(frame, (10, 10), (200, 50), (0, 255, 0), -1)
                cv2.putText(frame, "KEYFRAME", (20, 35),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 0), 2)

            cv2.imshow('Camera Feed', frame)

            # Break on 'q' key
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

    finally:
        camera.stop()
        cv2.destroyAllWindows()
        print("\nFinal Stats:", camera.get_stats())
