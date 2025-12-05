"""
LLM Integration: Handles communication with GPT-5 (or mock LLM)
"""

import time
import random
from typing import Dict, Optional
import config


class LLMIntegration:
    """Handles LLM API calls for answering questions"""

    def __init__(self, api_key: Optional[str] = None, use_mock: bool = True):
        self.api_key = api_key
        self.use_mock = use_mock
        self.total_calls = 0
        self.total_tokens_used = 0

        if use_mock:
            print("LLM running in MOCK mode (no API calls)")
        else:
            print(f"LLM initialized with model: {config.LLM_MODEL}")

    def generate_answer(self,
                       question: str,
                       context: Dict,
                       keyframe_data: Optional[Dict] = None,
                       ocr_text: Optional[str] = None) -> Dict:
        """
        Generate answer to a question given context

        Args:
            question: The question asked
            context: Memory context from MemorySubsystem
            keyframe_data: Optional keyframe information
            ocr_text: Optional OCR text from current screen

        Returns:
            Dict with 'answer', 'confidence', 'tokens_used'
        """
        self.total_calls += 1

        if self.use_mock:
            return self._mock_generate_answer(question, context, keyframe_data, ocr_text)
        else:
            return self._real_generate_answer(question, context, keyframe_data, ocr_text)

    def _mock_generate_answer(self,
                              question: str,
                              context: Dict,
                              keyframe_data: Optional[Dict],
                              ocr_text: Optional[str]) -> Dict:
        """Mock LLM response generator"""

        # Simulate API latency
        time.sleep(random.uniform(0.2, 0.5))

        # Generate contextual mock answers based on question type
        question_lower = question.lower()

        if 'error' in question_lower or 'fix' in question_lower:
            answers = [
                "This error typically occurs when a null value is passed to a function expecting a valid object. Check the variable initialization before this line.",
                "The NullPointerException suggests that you're trying to access a property on an undefined object. Add null checking before accessing the property.",
                "To fix this error, ensure that the object is properly initialized before use. You can add defensive checks or use optional chaining."
            ]
        elif 'function' in question_lower or 'does' in question_lower:
            answers = [
                "This function takes two parameters and returns their sum. It's a basic arithmetic operation commonly used in calculations.",
                "Based on the code visible, this function appears to process input data and return a transformed result.",
                "This function implements a core algorithm that handles the main business logic of the application."
            ]
        elif 'how' in question_lower or 'use' in question_lower:
            answers = [
                "To use this API, first import the module, then call the function with the required parameters. Here's an example: `result = api_function(param1, param2)`",
                "You can implement this by following these steps: 1) Initialize the object, 2) Set the configuration, 3) Call the main method.",
                "The recommended approach is to use the builder pattern. Create an instance, configure it, and then execute."
            ]
        elif 'what' in question_lower:
            answers = [
                "This code implements a data processing pipeline that transforms input through several stages before returning the result.",
                "The purpose of this code is to handle user authentication and session management in a secure manner.",
                "This is a utility function designed to validate input data and ensure it meets the required constraints."
            ]
        else:
            answers = [
                "Based on the current context and code visible, this appears to be handling data transformation.",
                "This implementation follows best practices for the framework you're using.",
                "The code structure suggests this is part of a larger system for processing user requests."
            ]

        # Select answer and add context-specific details
        base_answer = random.choice(answers)

        # Add OCR context if available
        if ocr_text:
            base_answer += f"\n\nI can see the code: `{ocr_text[:50]}...`"

        # Add recent context reference
        recent_events = context.get('recent_events', [])
        if len(recent_events) > 1:
            base_answer += f"\n\nBased on your previous {len(recent_events)} interactions, I'm providing context-aware assistance."

        # Mock token usage
        tokens_used = len(base_answer.split()) + len(question.split()) + 100  # Rough estimate
        self.total_tokens_used += tokens_used

        return {
            'answer': base_answer,
            'confidence': random.uniform(0.85, 0.98),
            'tokens_used': tokens_used,
            'model': config.LLM_MODEL,
            'timestamp': time.time()
        }

    def _real_generate_answer(self,
                             question: str,
                             context: Dict,
                             keyframe_data: Optional[Dict],
                             ocr_text: Optional[str]) -> Dict:
        """
        Real LLM API call (placeholder for actual implementation)
        In production, this would call OpenAI API or similar
        """
        # This would contain actual API call code
        # Example structure:

        # import openai
        # openai.api_key = self.api_key

        # messages = [
        #     {"role": "system", "content": "You are a helpful coding assistant..."},
        #     {"role": "user", "content": self._build_prompt(question, context, ocr_text)}
        # ]

        # response = openai.ChatCompletion.create(
        #     model=config.LLM_MODEL,
        #     messages=messages,
        #     max_tokens=config.LLM_MAX_TOKENS,
        #     temperature=config.LLM_TEMPERATURE
        # )

        # return {
        #     'answer': response.choices[0].message.content,
        #     'tokens_used': response.usage.total_tokens,
        #     ...
        # }

        # For now, fall back to mock
        return self._mock_generate_answer(question, context, keyframe_data, ocr_text)

    def _build_prompt(self,
                     question: str,
                     context: Dict,
                     ocr_text: Optional[str]) -> str:
        """Build the prompt for LLM with all context"""

        prompt_parts = []

        # Add context summary if available
        latest_summary = context.get('latest_summary')
        if latest_summary:
            summary_text = latest_summary.get('content', {}).get('summary_text', '')
            if summary_text:
                prompt_parts.append(f"Recent session summary: {summary_text}")

        # Add OCR text if available
        if ocr_text:
            prompt_parts.append(f"Current screen shows: {ocr_text}")

        # Add recent events
        recent_events = context.get('recent_events', [])
        if recent_events:
            prompt_parts.append(f"Recent events: {len(recent_events)} interactions")

        # Add the actual question
        prompt_parts.append(f"\nQuestion: {question}")

        return "\n\n".join(prompt_parts)

    def get_stats(self) -> Dict:
        """Get LLM usage statistics"""
        return {
            'total_calls': self.total_calls,
            'total_tokens_used': self.total_tokens_used,
            'average_tokens_per_call': self.total_tokens_used / max(1, self.total_calls),
            'mode': 'MOCK' if self.use_mock else 'REAL'
        }


if __name__ == "__main__":
    # Test the LLM integration
    import memory_subsystem

    llm = LLMIntegration(use_mock=True)
    memory = memory_subsystem.MemorySubsystem()

    # Add some context
    memory.add_question({'text': 'What does this function do?', 'confidence': 0.95})
    memory.add_ocr_event({'text': 'def calculate_sum(a, b): return a + b', 'confidence': 0.9})

    # Test various questions
    questions = [
        "What does this function do?",
        "How do I fix this error?",
        "Can you explain this code?",
        "What's the purpose of this API?"
    ]

    print("Testing LLM Integration with mock responses:\n")

    for question in questions:
        print(f"\n{'='*60}")
        print(f"Question: {question}")
        print(f"{'='*60}")

        context = memory.get_context_for_llm()
        result = llm.generate_answer(
            question=question,
            context=context,
            ocr_text="def calculate_sum(a, b): return a + b"
        )

        print(f"\nAnswer (confidence: {result['confidence']:.2%}):")
        print(result['answer'])
        print(f"\nTokens used: {result['tokens_used']}")

        # Add answer to memory
        memory.add_answer({'text': result['answer'], 'question': question})

    print(f"\n{'='*60}")
    print("LLM Stats:", llm.get_stats())
