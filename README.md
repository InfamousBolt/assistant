# Building a Real-Time Multimodal AI Assistant
(Camera + Non-User Audio + GPT-5) — Full Technical Architecture & Guide

## 🎉 Implementation Status

**✅ Python Prototype Complete!**

A fully functional Python-based prototype has been implemented with all core components:
- ✅ Camera subsystem with keyframe detection (SSIM-based)
- ✅ Audio subsystem with VAD, speaker identification, and STT
- ✅ OCR text extraction from video frames
- ✅ Memory and summarization system
- ✅ Mock LLM integration (ready for real API)
- ✅ Main orchestrator with event processing

**Quick Start:**
```bash
pip install -r requirements.txt
python main.py
```

See [SETUP.md](SETUP.md) for detailed installation and usage instructions.

---

## Table of Contents
1. Introduction
2. High-Level Overview
3. System Architecture
4. Detailed Component Breakdown  
5. Event-Based Processing
6. Latency & Performance
7. Cost Engineering
8. Full End-to-End Data Flow
9. Edge Cases & Reliability
10. Security & Privacy
11. Tech Stack Recommendations
12. Step-by-Step Implementation Guide
13. Appendix: Pseudocode

---

# 1. Introduction
This document defines the full technical blueprint to build an app that:

- Captures a **live camera feed**
- Listens to **any voice except the user’s**
- Extracts **visual + audio context**
- Understands questions asked by **other people**
- Uses GPT-5 (or similar) to answer intelligently
- Maintains **1 hour or more of continuous context**
- Never overruns the model’s token limit
- Responds instantly to real-time changes

---

# 2. High-Level Overview

### Input Streams
- **Video** → Camera feed  
- **Audio** → Microphone input  
- **User Voiceprint** → Used to ignore the user's voice  

### Processing
- On-device voice separation  
- On-device keyframe detection  
- On-device OCR  
- Cloud LLM for reasoning  

### Output
- Live answer overlays  
- Optional voice  
- Memory updates and summaries

---

# 3. System Architecture

```
 ┌──────────────────────────────────────────────────────────────┐
 │                      MOBILE DEVICE                           │
 ├──────────────────────────────────────────────────────────────┤
 │ Camera Feed → Frame Analyzer → Keyframe Detector              │
 │ Microphone → VAD → Speaker ID → STT                          │
 │ OCR/Text Detection → Embeddings                               │
 │ Summaries → Memory                                            │
 └───────────────────────┬──────────────────────────────────────┘
                         │
                         ▼
 ┌──────────────────────────────────────────────────────────────┐
 │                      CLOUD AI (GPT-5)                        │
 ├──────────────────────────────────────────────────────────────┤
 │ Receives: Keyframe, Question, Summary, OCR text              │
 │ Returns: Answer, Annotation                                  │
 └──────────────────────────────────────────────────────────────┘
```

---

# 4. Detailed Component Breakdown

## 4.1 Camera Subsystem
- Capture 5–10 fps  
- Analyze frames locally  
- **Do NOT send all frames**  
- Local OCR using MLKit/Tesseract  

## 4.2 Keyframe Extraction
Send frames only when meaningful change occurs:

- Text/code change  
- Screen update  
- Error message  
- Someone asks a question  

Techniques:
- SSIM threshold  
- Histogram diff  
- OCR diff  

## 4.3 Audio Subsystem
Pipeline:

1. **VAD** detects speech  
2. **ECAPA-TDNN** creates embeddings  
3. Compare against user voiceprint  
4. Reject user voice  
5. Accept non-user audio  
6. Whisper.cpp → STT  
7. Question detection  

## 4.4 Visual Understanding  
On-device OCR → Cloud vision + reasoning.

## 4.5 Summaries
Every 3–5 minutes compress:

- Interaction history  
- Code changes  
- Errors  
- Key frames  

Stored as JSON memory chunks.

## 4.6 Memory System
Use vector DB + recency context.

## 4.7 Multimodal LLM Integration
Send:

- Latest keyframe  
- Extracted code  
- Question  
- Summary  

Receive:

- Answer  
- Optional annotations  

---

# 5. Event-Based Processing
Triggers:

- Non-user question detected  
- Significant frame change  
- New code appears  
- Error messages  

---

# 6. Latency & Performance
Expected times:

| Module | Time |
|--------|------|
| VAD | ~1 ms |
| Speaker ID | 10–20 ms |
| STT | 80–150 ms |
| Keyframe detection | 5–10 ms |
| LLM call | 200–500 ms |

Total: **0.5–1.1 seconds**.

---

# 7. Cost Engineering

**Hybrid approach cost:**  
$0.50–$2.00 per user per hour.

Because keyframes reduce images from thousands → ~20–40/hr.

---

# 8. Full End-to-End Data Flow

```
Camera → Keyframe? → LLM  
Audio → VAD → Speaker ID → STT → Question? → LLM  
Summaries → Memory → LLM  
LLM → UI Overlay  
```

---

# 9. Edge Cases
- Overlapping voices → diarization  
- Poor lighting → OCR fallback  
- Rapid changes → throttle frames  
- Large code → chunking  

---

# 10. Security & Privacy
- No raw video/audio stored  
- Voiceprints hashed  
- All LLM traffic encrypted  

---

# 11. Tech Stack Recommendations

### On-device
- Swift + AVFoundation  
- Kotlin + CameraX  
- Silero VAD  
- ECAPA-TDNN  
- Whisper.cpp  

### Cloud
- GPT‑5 Realtime  
- Optional vector DB  

---

# 12. Step-by-Step Implementation Guide

### Step 1 — Camera pipeline  
- SSIM + OCR diff  
- Capture keyframes  

### Step 2 — Audio  
- VAD  
- Speaker ID  
- Whisper.cpp  

### Step 3 — Question detection  
Regex or classifier.

### Step 4 — Summaries  
Periodic compression.

### Step 5 — LLM integration  
Send keyframe + summary + question.

### Step 6 — UI overlay  
Floating panel, AR-style.

---

# 13. Appendix: Pseudocode

### Keyframe Detection
```python
if ssim(prev_frame, new_frame) < THRESHOLD:
    send(new_frame)
```

### Speaker Filtering
```python
embedding = ecapa(audio)
if cosine(embedding, user_voiceprint) < 0.75:
    process()
```

### Summarization
```python
if now - last_summary > interval:
    save(summary)
```

### LLM Call
```python
payload = {
  "frame": keyframe,
  "question": q,
  "summary": memory.latest(),
  "ocr_text": text
}
```
