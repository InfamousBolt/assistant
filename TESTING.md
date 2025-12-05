# Testing Guide

## ✅ Quick Test (Just Completed)

You just ran the comprehensive test suite! Here's what was tested:

- ✅ Memory & Summarization System
- ✅ LLM Integration with Mock Responses
- ✅ OCR Subsystem
- ✅ Keyframe Detection Algorithm
- ✅ Audio Processing Pipeline
- ✅ Full System Integration

## 🚀 How to Test Each Component

### 1. **Comprehensive Test Suite** (Recommended First)
```bash
python test_system.py
```
**What it tests:** All components working together without hardware
**Duration:** ~2 seconds
**Requires:** No camera/microphone needed

---

### 2. **Memory System**
```bash
python memory_subsystem.py
```
**What it does:**
- Creates sample interactions
- Generates context for LLM
- Creates periodic summaries
- Tests save/load functionality

**Expected output:**
- Recent context display
- Summary generation
- Statistics

---

### 3. **LLM Integration**
```bash
python llm_integration.py
```
**What it does:**
- Tests mock LLM with various question types
- Shows contextual answer generation
- Displays token usage stats

**Expected output:**
```
Question: What does this function do?
Answer (confidence: 95%):
This function takes two parameters and returns...
```

---

### 4. **Camera + Keyframe Detection** (Requires Camera)
```bash
python camera_subsystem.py
```
**What it does:**
- Opens your camera
- Shows live feed
- Highlights keyframes in green when visual changes detected

**Controls:**
- Move something in front of camera to trigger keyframes
- Press `q` to quit

**Expected behavior:**
- Green "KEYFRAME" indicator when scene changes
- Stats showing keyframe ratio

**Troubleshooting:**
- If camera doesn't open: Check if camera is connected
- Try different camera: Edit `CameraSubsystem(camera_id=1)`
- No camera? Use `test_system.py` instead

---

### 5. **OCR Text Detection** (Requires Camera)
```bash
python ocr_subsystem.py
```
**What it does:**
- Captures camera feed
- Runs OCR on keyframes
- Extracts text from what camera sees

**How to test:**
- Show code on your screen to the camera
- Show error messages
- Show any text

**Expected output:**
```
📄 OCR Result (confidence: 0.90):
   def calculate_sum(a, b): return a + b
```

**Note:** Without tesseract installed, uses mock OCR

---

### 6. **Audio Processing** (Requires Microphone)
```bash
python audio_subsystem.py
```
**What it does:**
- Listens for speech
- Filters user voice
- Detects questions

**Expected output:**
```
🎤 Non-user question detected: "What does this function do?"
```

**Note:** Currently uses mock audio (simulated speech)

---

### 7. **Full System** (Requires Camera, Optional Microphone)
```bash
python main.py
```

**What it does:**
- Runs complete multimodal assistant
- Shows live camera feed with overlays
- Processes questions and generates answers
- Displays real-time stats

**Controls:**
- `q` - Quit
- `s` - Show statistics
- `c` - Clear answer overlay

**Expected overlay:**
```
Runtime: 45s
Questions: 3
Memory: 12 chunks
```

---

## 🧪 Testing Scenarios

### Scenario 1: Code Review Assistant
1. Run `python main.py`
2. Show code on your screen to camera
3. Say (or simulate): "What does this code do?"
4. See answer appear in overlay

### Scenario 2: Error Help
1. Run the system
2. Show an error message
3. Ask: "How do I fix this?"
4. Get contextual answer

### Scenario 3: Long Session
1. Run for several minutes
2. See periodic summaries created every 3 minutes
3. Check memory stats with `s` key

---

## 📊 What Success Looks Like

### test_system.py Output:
```
✅ ALL TESTS COMPLETED SUCCESSFULLY!

📊 OVERALL SYSTEM STATUS:
  Memory chunks stored: 12
  Total questions processed: 3
  LLM calls made: 4
  Total tokens used: 586
  Summaries created: 2
```

### camera_subsystem.py Output:
```
Camera started: 640x480 @ 10 fps
🔑 Keyframe detected! (SSIM: 0.742)
🔑 Keyframe detected! (SSIM: 0.821)

Final Stats: {
  'total_frames': 156,
  'keyframes': 12,
  'keyframe_ratio': 0.077
}
```

### main.py Output:
```
🎯 Multimodal AI Assistant is RUNNING

Monitoring:
  📹 Camera for visual changes
  🎤 Audio for non-user questions
  📝 Screen text via OCR
```

---

## 🐛 Common Issues

### "Camera not found"
- **Cause:** No webcam connected
- **Solution:** Use `test_system.py` for testing without hardware

### "Tesseract not installed"
- **Cause:** OCR engine not installed
- **Solution:** OCR falls back to mock mode (still works!)
- **To fix:** `sudo apt-get install tesseract-ocr` (Linux)

### "pyaudio not available"
- **Cause:** Audio libraries not installed (expected in container)
- **Solution:** Audio uses mock mode (still works!)
- **To fix:** Install system audio libraries (see SETUP.md)

### "No module named 'cv2'"
- **Cause:** OpenCV not installed
- **Solution:** `pip install -r requirements-minimal.txt`

---

## 🎯 Recommended Testing Order

1. **First Time?** → `python test_system.py`
   - Tests everything without hardware
   - Takes 2 seconds
   - Shows all features

2. **Have Camera?** → `python camera_subsystem.py`
   - Tests keyframe detection
   - Visual feedback

3. **Want Full Experience?** → `python main.py`
   - Complete system
   - Real-time processing

4. **Debugging?** → Test individual modules
   - `python memory_subsystem.py`
   - `python llm_integration.py`
   - etc.

---

## 📈 Performance Expectations

| Component | Latency | Notes |
|-----------|---------|-------|
| Keyframe detection | ~10ms | SSIM calculation |
| OCR (mock) | ~5ms | Instant mock response |
| OCR (real) | ~100ms | Tesseract processing |
| Audio VAD | ~1ms | WebRTC VAD |
| LLM (mock) | ~300ms | Simulated API delay |
| Memory lookup | <1ms | In-memory operations |

**Total pipeline (mock):** ~0.5 seconds per question

---

## 🎓 Understanding the Output

### Keyframe Detection
- **SSIM > 0.85:** Not a keyframe (similar to previous)
- **SSIM < 0.85:** Keyframe! (significant change)

### Confidence Scores
- **> 0.9:** High confidence
- **0.7-0.9:** Medium confidence
- **< 0.7:** Low confidence

### Memory Stats
- **memory_chunks_stored:** Number of events remembered
- **total_interactions:** Questions answered
- **summaries_created:** Number of context compressions

---

## 💡 Next Steps After Testing

1. **Add Real LLM:** Configure OpenAI API key
2. **Deploy to Mobile:** Port to iOS/Android
3. **Optimize:** Profile performance bottlenecks
4. **Extend:** Add more features from README.md

---

## 🆘 Need Help?

- Check **SETUP.md** for installation issues
- Check **README.md** for architecture details
- Run `python <module>.py --help` for module-specific help
- All modules have `if __name__ == "__main__"` test code
