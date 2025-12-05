#!/usr/bin/env python3
"""
Main Orchestrator: Real-Time Multimodal AI Assistant
Coordinates camera, audio, OCR, memory, and LLM subsystems
"""

import time
import sys
import threading
from typing import Optional
import cv2

import config
from camera_subsystem import CameraSubsystem
from audio_subsystem import AudioSubsystem
from ocr_subsystem import OCRSubsystem
from memory_subsystem import MemorySubsystem
from llm_integration import LLMIntegration


class MultimodalAssistant:
    """Main orchestrator for the real-time AI assistant"""

    def __init__(self, use_mock_llm: bool = True):
        print("🚀 Initializing Multimodal AI Assistant...\n")

        # Initialize all subsystems
        self.camera = CameraSubsystem()
        self.audio = AudioSubsystem()
        self.ocr = OCRSubsystem()
        self.memory = MemorySubsystem()
        self.llm = LLMIntegration(use_mock=use_mock_llm)

        # State
        self.is_running = False
        self.current_keyframe = None
        self.current_ocr_text = ""
        self.answer_overlay = ""

        # Stats
        self.questions_answered = 0
        self.start_time = None

    def start(self) -> bool:
        """Start all subsystems"""
        print("Starting subsystems...")

        # Start camera
        if not self.camera.start():
            print("❌ Failed to start camera")
            return False
        print("✅ Camera started")

        # Start audio
        self.audio.load_user_voiceprint(config.VOICEPRINT_PATH)
        if not self.audio.start():
            print("❌ Failed to start audio")
            self.camera.stop()
            return False
        print("✅ Audio started")

        # Load previous memory if exists
        self.memory.load_from_file(config.MEMORY_DB_PATH)
        print("✅ Memory system ready")

        print("✅ OCR system ready")
        print("✅ LLM integration ready")

        self.is_running = True
        self.start_time = time.time()

        print("\n" + "="*60)
        print("🎯 Multimodal AI Assistant is RUNNING")
        print("="*60)
        print("\nMonitoring:")
        print("  📹 Camera for visual changes")
        print("  🎤 Audio for non-user questions")
        print("  📝 Screen text via OCR")
        print("\nPress 'q' to quit, 's' to show stats")
        print("="*60 + "\n")

        return True

    def stop(self):
        """Stop all subsystems and save state"""
        print("\n\n🛑 Shutting down...")

        self.is_running = False

        # Save memory
        self.memory.save_to_file(config.MEMORY_DB_PATH)

        # Stop subsystems
        self.camera.stop()
        self.audio.stop()

        print("✅ All subsystems stopped")

    def process_camera_frame(self):
        """Process camera feed and detect keyframes"""
        result = self.camera.get_frame_with_keyframe_detection()
        if result is None:
            return None, False

        frame, is_keyframe = result

        if is_keyframe:
            # Run OCR on keyframe
            ocr_result = self.ocr.extract_text(frame)

            if ocr_result['changed']:
                self.current_ocr_text = ocr_result['text']

                # Add to memory
                self.memory.add_ocr_event(ocr_result)
                self.memory.add_keyframe({
                    'ocr_text': ocr_result['text'],
                    'confidence': ocr_result['confidence']
                })

            self.current_keyframe = frame

        return frame, is_keyframe

    def process_audio_stream(self):
        """Process audio and detect non-user questions"""
        result = self.audio.process_audio_stream()

        if result:  # Non-user question detected
            question = result['text']
            print(f"\n{'='*60}")
            print(f"❓ Question: {question}")
            print(f"{'='*60}")

            # Add question to memory
            self.memory.add_question(result)

            # Get context for LLM
            context = self.memory.get_context_for_llm()

            # Generate answer
            print("🤔 Generating answer...")
            answer_result = self.llm.generate_answer(
                question=question,
                context=context,
                ocr_text=self.current_ocr_text
            )

            answer = answer_result['answer']
            print(f"\n💡 Answer (confidence: {answer_result['confidence']:.1%}):")
            print(f"{answer}")
            print("="*60 + "\n")

            # Add answer to memory
            self.memory.add_answer({
                'text': answer,
                'question': question
            })

            # Update overlay
            self.answer_overlay = f"Q: {question[:40]}...\nA: {answer[:100]}..."
            self.questions_answered += 1

            return True

        return False

    def check_and_create_summary(self):
        """Check if summary should be created and create it"""
        if self.memory.should_create_summary():
            print("\n" + "="*60)
            print("📊 Creating periodic summary...")
            summary = self.memory.create_summary()
            print(f"Summary: {summary['summary_text']}")
            print("="*60 + "\n")

    def render_overlay(self, frame):
        """Render information overlay on frame"""
        height, width = frame.shape[:2]

        # Semi-transparent overlay background
        overlay = frame.copy()

        # Stats panel (top-right)
        stats_text = [
            f"Runtime: {int(time.time() - self.start_time)}s",
            f"Questions: {self.questions_answered}",
            f"Memory: {len(self.memory.memory_chunks)} chunks"
        ]

        y_offset = 30
        for i, text in enumerate(stats_text):
            cv2.rectangle(overlay, (width-250, y_offset-20), (width-10, y_offset+5), (0, 0, 0), -1)
            cv2.putText(overlay, text, (width-240, y_offset),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 1)
            y_offset += 30

        # Answer overlay (bottom)
        if self.answer_overlay:
            lines = self.answer_overlay.split('\n')
            y_start = height - 80

            cv2.rectangle(overlay, (10, y_start-10), (width-10, height-10), (0, 0, 0), -1)

            for i, line in enumerate(lines[:2]):  # Show max 2 lines
                cv2.putText(overlay, line, (20, y_start + i*25),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)

        # Blend overlay
        cv2.addWeighted(overlay, 0.7, frame, 0.3, 0, frame)

        return frame

    def show_stats(self):
        """Display comprehensive statistics"""
        print("\n" + "="*60)
        print("📊 SYSTEM STATISTICS")
        print("="*60)

        print("\n🎬 Camera:")
        for key, val in self.camera.get_stats().items():
            print(f"  {key}: {val}")

        print("\n🎤 Audio:")
        for key, val in self.audio.get_stats().items():
            print(f"  {key}: {val}")

        print("\n📝 OCR:")
        for key, val in self.ocr.get_stats().items():
            print(f"  {key}: {val}")

        print("\n🧠 Memory:")
        for key, val in self.memory.get_stats().items():
            print(f"  {key}: {val}")

        print("\n🤖 LLM:")
        for key, val in self.llm.get_stats().items():
            print(f"  {key}: {val}")

        print("\n🎯 Overall:")
        print(f"  questions_answered: {self.questions_answered}")
        print(f"  runtime_seconds: {int(time.time() - self.start_time)}")

        print("="*60 + "\n")

    def run(self):
        """Main event loop"""
        if not self.start():
            print("Failed to start assistant")
            return

        # Run audio processing in separate thread
        audio_thread = threading.Thread(target=self._audio_loop, daemon=True)
        audio_thread.start()

        try:
            while self.is_running:
                # Process camera frame
                frame, is_keyframe = self.process_camera_frame()

                if frame is not None:
                    # Render overlay
                    display_frame = self.render_overlay(frame)

                    # Show frame
                    cv2.imshow('AI Assistant', display_frame)

                # Check for summary creation
                self.check_and_create_summary()

                # Handle keyboard input
                key = cv2.waitKey(1) & 0xFF
                if key == ord('q'):
                    print("\nQuitting...")
                    break
                elif key == ord('s'):
                    self.show_stats()
                elif key == ord('c'):
                    # Clear answer overlay
                    self.answer_overlay = ""

                time.sleep(0.01)  # Small delay to prevent CPU overuse

        except KeyboardInterrupt:
            print("\n\nInterrupted by user")

        finally:
            self.stop()
            cv2.destroyAllWindows()
            self.show_stats()

    def _audio_loop(self):
        """Separate thread for continuous audio processing"""
        while self.is_running:
            try:
                self.process_audio_stream()
                time.sleep(0.01)
            except Exception as e:
                print(f"Audio processing error: {e}")
                time.sleep(0.1)


def main():
    """Entry point"""
    print("\n" + "="*60)
    print("Real-Time Multimodal AI Assistant")
    print("="*60 + "\n")

    # Check if real LLM mode requested
    use_mock = True
    if len(sys.argv) > 1 and sys.argv[1] == '--real-llm':
        use_mock = False
        print("⚠️  Running with REAL LLM (requires API key)")
    else:
        print("ℹ️  Running with MOCK LLM (no API calls)")

    # Create and run assistant
    assistant = MultimodalAssistant(use_mock_llm=use_mock)

    try:
        assistant.run()
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        print("\n✅ Assistant stopped")


if __name__ == "__main__":
    main()
