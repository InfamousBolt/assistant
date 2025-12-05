"""
Memory & Summarization Subsystem: Manages context, summaries, and memory chunks
"""

import json
import time
from typing import List, Dict, Optional
from collections import deque
import config


class MemoryChunk:
    """Represents a chunk of memory with timestamp and content"""

    def __init__(self, chunk_type: str, content: Dict, timestamp: float = None):
        self.chunk_type = chunk_type  # 'keyframe', 'question', 'answer', 'summary', 'ocr'
        self.content = content
        self.timestamp = timestamp or time.time()

    def to_dict(self) -> Dict:
        """Convert to dictionary for serialization"""
        return {
            'type': self.chunk_type,
            'content': self.content,
            'timestamp': self.timestamp,
            'time_str': time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(self.timestamp))
        }

    @classmethod
    def from_dict(cls, data: Dict):
        """Create from dictionary"""
        return cls(data['type'], data['content'], data['timestamp'])


class MemorySubsystem:
    """Manages conversation memory, context, and summarization"""

    def __init__(self):
        self.memory_chunks = deque(maxlen=config.MAX_MEMORY_CHUNKS)
        self.summaries = []
        self.last_summary_time = time.time()
        self.session_start_time = time.time()
        self.total_interactions = 0

    def add_keyframe(self, frame_data: Dict):
        """Add a keyframe event to memory"""
        chunk = MemoryChunk('keyframe', {
            'description': 'Visual keyframe captured',
            'ocr_text': frame_data.get('ocr_text', ''),
            'confidence': frame_data.get('confidence', 0)
        })
        self.memory_chunks.append(chunk)

    def add_question(self, question_data: Dict):
        """Add a question to memory"""
        chunk = MemoryChunk('question', {
            'text': question_data['text'],
            'confidence': question_data.get('confidence', 1.0)
        })
        self.memory_chunks.append(chunk)
        self.total_interactions += 1

    def add_answer(self, answer_data: Dict):
        """Add an answer to memory"""
        chunk = MemoryChunk('answer', {
            'text': answer_data['text'],
            'question': answer_data.get('question', '')
        })
        self.memory_chunks.append(chunk)

    def add_ocr_event(self, ocr_data: Dict):
        """Add OCR text detection to memory"""
        if ocr_data.get('text'):
            chunk = MemoryChunk('ocr', {
                'text': ocr_data['text'],
                'confidence': ocr_data.get('confidence', 0),
                'word_count': ocr_data.get('word_count', 0)
            })
            self.memory_chunks.append(chunk)

    def should_create_summary(self) -> bool:
        """Check if it's time to create a summary"""
        elapsed = time.time() - self.last_summary_time
        return elapsed >= config.SUMMARY_INTERVAL_SECONDS

    def create_summary(self) -> Dict:
        """
        Create a summary of recent interactions
        In production, this would use LLM to compress context
        """
        if not self.memory_chunks:
            return {}

        # Gather recent events
        recent_questions = []
        recent_ocr = []
        recent_keyframes = 0

        for chunk in self.memory_chunks:
            if chunk.chunk_type == 'question':
                recent_questions.append(chunk.content['text'])
            elif chunk.chunk_type == 'ocr':
                recent_ocr.append(chunk.content['text'])
            elif chunk.chunk_type == 'keyframe':
                recent_keyframes += 1

        # Create summary
        summary = {
            'timeframe': {
                'start': self.last_summary_time,
                'end': time.time(),
                'duration_seconds': time.time() - self.last_summary_time
            },
            'statistics': {
                'questions_asked': len(recent_questions),
                'keyframes_captured': recent_keyframes,
                'ocr_events': len(recent_ocr)
            },
            'questions': recent_questions[-5:],  # Last 5 questions
            'detected_text': list(set(recent_ocr))[:3],  # Unique OCR text samples
            'summary_text': self._generate_summary_text(recent_questions, recent_ocr)
        }

        # Store summary
        summary_chunk = MemoryChunk('summary', summary)
        self.summaries.append(summary_chunk)
        self.last_summary_time = time.time()

        print(f"\n📊 Summary created: {summary['statistics']}")

        return summary

    def _generate_summary_text(self, questions: List[str], ocr_texts: List[str]) -> str:
        """Generate human-readable summary text"""
        parts = []

        if questions:
            parts.append(f"Received {len(questions)} questions about code and errors")

        if ocr_texts:
            unique_texts = set(ocr_texts)
            parts.append(f"Detected {len(unique_texts)} unique text segments on screen")

        if not parts:
            parts.append("Monitoring session with no significant activity")

        return ". ".join(parts) + "."

    def get_recent_context(self, max_chunks: int = 10) -> List[Dict]:
        """Get recent memory chunks for context"""
        recent = list(self.memory_chunks)[-max_chunks:]
        return [chunk.to_dict() for chunk in recent]

    def get_latest_summary(self) -> Optional[Dict]:
        """Get the most recent summary"""
        if not self.summaries:
            return None
        return self.summaries[-1].to_dict()

    def get_context_for_llm(self) -> Dict:
        """
        Build context package for LLM
        This includes recent events + latest summary
        """
        context = {
            'session_duration': time.time() - self.session_start_time,
            'total_interactions': self.total_interactions,
            'latest_summary': self.get_latest_summary(),
            'recent_events': self.get_recent_context(max_chunks=5)
        }

        return context

    def save_to_file(self, filepath: str):
        """Save memory state to JSON file"""
        data = {
            'session_start': self.session_start_time,
            'total_interactions': self.total_interactions,
            'memory_chunks': [chunk.to_dict() for chunk in self.memory_chunks],
            'summaries': [summary.to_dict() for summary in self.summaries]
        }

        try:
            with open(filepath, 'w') as f:
                json.dump(data, f, indent=2)
            print(f"Memory saved to {filepath}")
        except Exception as e:
            print(f"Error saving memory: {e}")

    def load_from_file(self, filepath: str) -> bool:
        """Load memory state from JSON file"""
        try:
            with open(filepath, 'r') as f:
                data = json.load(f)

            self.session_start_time = data.get('session_start', time.time())
            self.total_interactions = data.get('total_interactions', 0)

            # Load memory chunks
            self.memory_chunks.clear()
            for chunk_data in data.get('memory_chunks', []):
                chunk = MemoryChunk.from_dict(chunk_data)
                self.memory_chunks.append(chunk)

            # Load summaries
            self.summaries.clear()
            for summary_data in data.get('summaries', []):
                summary = MemoryChunk.from_dict(summary_data)
                self.summaries.append(summary)

            print(f"Memory loaded from {filepath}")
            return True

        except FileNotFoundError:
            print(f"No saved memory found at {filepath}")
            return False
        except Exception as e:
            print(f"Error loading memory: {e}")
            return False

    def get_stats(self) -> Dict:
        """Get memory system statistics"""
        return {
            'session_duration': time.time() - self.session_start_time,
            'total_interactions': self.total_interactions,
            'memory_chunks_stored': len(self.memory_chunks),
            'summaries_created': len(self.summaries),
            'time_since_last_summary': time.time() - self.last_summary_time
        }

    def clear(self):
        """Clear all memory (useful for testing)"""
        self.memory_chunks.clear()
        self.summaries.clear()
        self.last_summary_time = time.time()
        self.total_interactions = 0
        print("Memory cleared")


if __name__ == "__main__":
    # Test the memory subsystem
    memory = MemorySubsystem()

    print("Testing memory subsystem...\n")

    # Simulate some events
    memory.add_question({'text': 'What does this function do?', 'confidence': 0.95})
    time.sleep(0.1)

    memory.add_ocr_event({'text': 'def calculate_sum(a, b):', 'confidence': 0.9, 'word_count': 4})
    time.sleep(0.1)

    memory.add_answer({'text': 'This function calculates the sum of two numbers', 'question': 'What does this function do?'})
    time.sleep(0.1)

    memory.add_keyframe({'ocr_text': 'Error: NullPointerException', 'confidence': 0.85})
    time.sleep(0.1)

    memory.add_question({'text': 'How do I fix this error?', 'confidence': 0.92})

    # Get context
    print("Recent Context:")
    context = memory.get_context_for_llm()
    print(json.dumps(context, indent=2))

    # Test summary creation
    print("\n\nForcing summary creation...")
    memory.last_summary_time = time.time() - config.SUMMARY_INTERVAL_SECONDS - 1
    if memory.should_create_summary():
        summary = memory.create_summary()
        print("\nSummary:")
        print(json.dumps(summary, indent=2))

    # Test save/load
    print("\n\nTesting save/load...")
    memory.save_to_file('test_memory.json')

    new_memory = MemorySubsystem()
    new_memory.load_from_file('test_memory.json')

    print("\nStats:", memory.get_stats())
