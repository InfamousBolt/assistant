#!/usr/bin/env python3
"""
Test script for demonstrating the multimodal AI assistant
without requiring real camera/audio hardware
"""

import time
import json

print("="*70)
print("MULTIMODAL AI ASSISTANT - TEST SUITE")
print("="*70)

# Test 1: Memory Subsystem
print("\n📋 TEST 1: Memory & Summarization System")
print("-"*70)

from memory_subsystem import MemorySubsystem

memory = MemorySubsystem()

# Simulate some interactions
print("Adding sample interactions...")
memory.add_question({'text': 'What does this function do?', 'confidence': 0.95})
time.sleep(0.1)

memory.add_ocr_event({'text': 'def calculate_sum(a, b): return a + b', 'confidence': 0.9, 'word_count': 6})
time.sleep(0.1)

memory.add_answer({'text': 'This function calculates the sum of two numbers', 'question': 'What does this function do?'})
time.sleep(0.1)

memory.add_keyframe({'ocr_text': 'Error: NullPointerException', 'confidence': 0.85})
time.sleep(0.1)

memory.add_question({'text': 'How do I fix this error?', 'confidence': 0.92})

print(f"✅ Added {len(memory.memory_chunks)} memory chunks")

# Get context
context = memory.get_context_for_llm()
print(f"✅ Context ready with {len(context['recent_events'])} recent events")

# Force summary creation
memory.last_summary_time = time.time() - 200
if memory.should_create_summary():
    summary = memory.create_summary()
    print(f"✅ Summary created: {summary['summary_text']}")

print(f"\n📊 Memory Stats:")
for key, val in memory.get_stats().items():
    print(f"   {key}: {val}")


# Test 2: LLM Integration
print("\n\n🤖 TEST 2: LLM Integration (Mock Mode)")
print("-"*70)

from llm_integration import LLMIntegration

llm = LLMIntegration(use_mock=True)

test_questions = [
    "What does this function do?",
    "How do I fix this error?",
    "Can you explain this code?",
]

for i, question in enumerate(test_questions, 1):
    print(f"\n[Question {i}] {question}")

    result = llm.generate_answer(
        question=question,
        context=memory.get_context_for_llm(),
        ocr_text="def calculate_sum(a, b): return a + b"
    )

    print(f"Answer (confidence: {result['confidence']:.1%}):")
    print(f"  {result['answer'][:100]}...")
    print(f"  Tokens: {result['tokens_used']}")

    memory.add_answer({'text': result['answer'], 'question': question})

print(f"\n📊 LLM Stats:")
for key, val in llm.get_stats().items():
    print(f"   {key}: {val}")


# Test 3: OCR Subsystem (without camera)
print("\n\n📝 TEST 3: OCR Subsystem")
print("-"*70)

from ocr_subsystem import OCRSubsystem
import numpy as np

ocr = OCRSubsystem()

# Create mock frames (different brightnesses simulate different content)
mock_frames = [
    np.ones((480, 640, 3), dtype=np.uint8) * 180,  # Bright
    np.ones((480, 640, 3), dtype=np.uint8) * 120,  # Medium
    np.ones((480, 640, 3), dtype=np.uint8) * 60,   # Dark
]

print("Running OCR on mock frames...")
for i, frame in enumerate(mock_frames, 1):
    result = ocr.extract_text(frame)
    if result['text']:
        print(f"  Frame {i}: \"{result['text'][:50]}...\" (conf: {result['confidence']:.2f})")

print(f"\n📊 OCR Stats:")
for key, val in ocr.get_stats().items():
    print(f"   {key}: {val}")


# Test 4: Camera Keyframe Detection (simulated)
print("\n\n📹 TEST 4: Keyframe Detection Algorithm")
print("-"*70)

from camera_subsystem import CameraSubsystem

camera = CameraSubsystem()

# Test SSIM keyframe detection with mock frames
print("Testing keyframe detection with simulated frames...")

# Create different frames
frame1 = np.ones((480, 640, 3), dtype=np.uint8) * 100
frame2 = np.ones((480, 640, 3), dtype=np.uint8) * 100  # Same as frame1
frame3 = np.ones((480, 640, 3), dtype=np.uint8) * 200  # Different

camera.previous_frame = frame1
is_keyframe, similarity = camera.is_keyframe(frame2)
print(f"  Similar frames: is_keyframe={is_keyframe}, similarity={similarity:.3f}")

is_keyframe, similarity = camera.is_keyframe(frame3)
print(f"  Different frames: is_keyframe={is_keyframe}, similarity={similarity:.3f}")


# Test 5: Audio Processing (mock)
print("\n\n🎤 TEST 5: Audio Processing Pipeline")
print("-"*70)

from audio_subsystem import AudioSubsystem

audio = AudioSubsystem()
audio.load_user_voiceprint('dummy_path.npy')

print("Simulating audio stream processing...")
question_count = 0
max_attempts = 20

for i in range(max_attempts):
    result = audio.process_audio_stream()
    if result:
        question_count += 1
        print(f"  [{question_count}] Detected: \"{result['text']}\" (conf: {result['confidence']:.2%})")

        if question_count >= 3:  # Get 3 questions for demo
            break

print(f"\n📊 Audio Stats:")
for key, val in audio.get_stats().items():
    print(f"   {key}: {val}")


# Test 6: Full Integration Test
print("\n\n🎯 TEST 6: Full System Integration")
print("-"*70)

print("Simulating complete interaction flow...")

# 1. Keyframe detected
print("\n1️⃣  Keyframe detected with code change")
keyframe_data = {
    'ocr_text': 'def process_data(items): return [x*2 for x in items]',
    'confidence': 0.92
}
memory.add_keyframe(keyframe_data)
memory.add_ocr_event({'text': keyframe_data['ocr_text'], 'confidence': 0.92, 'word_count': 8})

# 2. Question detected
print("2️⃣  Non-user question detected")
question = "What does this process_data function do?"
memory.add_question({'text': question, 'confidence': 0.94})

# 3. Generate answer
print("3️⃣  Generating contextual answer...")
context = memory.get_context_for_llm()
answer = llm.generate_answer(
    question=question,
    context=context,
    ocr_text=keyframe_data['ocr_text']
)

print(f"\n❓ Question: {question}")
print(f"💡 Answer: {answer['answer']}")
print(f"   Confidence: {answer['confidence']:.1%}")
print(f"   Tokens used: {answer['tokens_used']}")

memory.add_answer({'text': answer['answer'], 'question': question})

# 4. Summary
print("\n4️⃣  Creating session summary...")
memory.last_summary_time = time.time() - 200
summary = memory.create_summary()
print(f"   {summary['summary_text']}")
print(f"   Questions: {summary['statistics']['questions_asked']}")
print(f"   Keyframes: {summary['statistics']['keyframes_captured']}")


# Final Summary
print("\n\n" + "="*70)
print("✅ ALL TESTS COMPLETED SUCCESSFULLY!")
print("="*70)

print("\n📊 OVERALL SYSTEM STATUS:")
print(f"  Memory chunks stored: {len(memory.memory_chunks)}")
print(f"  Total questions processed: {memory.total_interactions}")
print(f"  LLM calls made: {llm.total_calls}")
print(f"  Total tokens used: {llm.total_tokens_used}")
print(f"  Summaries created: {len(memory.summaries)}")

print("\n💡 NEXT STEPS:")
print("  1. Run individual tests: python camera_subsystem.py")
print("  2. Run individual tests: python memory_subsystem.py")
print("  3. Run individual tests: python llm_integration.py")
print("  4. Run full system: python main.py (requires camera)")
print("  5. See SETUP.md for more options")

print("\n" + "="*70)
