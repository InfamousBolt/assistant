# Setup Guide - Real-Time Multimodal AI Assistant

## Quick Start

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Install System Dependencies

#### Linux (Ubuntu/Debian)
```bash
sudo apt-get update
sudo apt-get install -y python3-opencv tesseract-ocr portaudio19-dev
```

#### macOS
```bash
brew install opencv tesseract portaudio
```

#### Windows
- Install OpenCV: Download from https://opencv.org/
- Install Tesseract: Download from https://github.com/UB-Mannheim/tesseract/wiki
- Install PortAudio: Download from http://www.portaudio.com/

### 3. Run the Application

```bash
python main.py
```

Or make it executable:
```bash
chmod +x main.py
./main.py
```

## Running Individual Subsystems

Test each component separately:

### Camera Subsystem
```bash
python camera_subsystem.py
```
- Shows live camera feed
- Highlights keyframes in green
- Press 'q' to quit

### Audio Subsystem
```bash
python audio_subsystem.py
```
- Listens for non-user speech
- Detects questions automatically
- Press Ctrl+C to stop

### OCR Subsystem
```bash
python ocr_subsystem.py
```
- Runs OCR on camera keyframes
- Displays detected text
- Press 'q' to quit

### Memory Subsystem
```bash
python memory_subsystem.py
```
- Tests memory storage and summarization
- Creates test data and summaries

### LLM Integration
```bash
python llm_integration.py
```
- Tests mock LLM responses
- Shows various question types

## Configuration

Edit `config.py` to customize:

- **Camera settings**: FPS, resolution, keyframe threshold
- **Audio settings**: Sample rate, VAD threshold, speaker ID threshold
- **Memory settings**: Summary interval, max memory chunks
- **LLM settings**: Model, max tokens, temperature

## Keyboard Controls

When running `main.py`:

- **q**: Quit the application
- **s**: Show detailed statistics
- **c**: Clear answer overlay

## Mock vs Real Mode

### Mock Mode (Default)
All subsystems use simulated data - no API calls or heavy processing:
- Mock audio with simulated questions
- Mock LLM responses
- Mock speaker identification
- Works without webcam/microphone

### Real Mode
Uses actual hardware and could use real APIs:
```bash
python main.py --real-llm
```

**Note**: Real LLM mode requires API key configuration (not yet implemented).

## Troubleshooting

### Camera not working
- Check if camera is connected: `ls /dev/video*`
- Try different camera ID in `CameraSubsystem(camera_id=1)`
- Test with: `python camera_subsystem.py`

### Audio not working
- Check audio devices: `python -m pyaudio`
- Verify microphone permissions
- Test with: `python audio_subsystem.py`

### OCR not detecting text
- Install tesseract: Check with `tesseract --version`
- Improve lighting conditions
- Show larger, high-contrast text to camera

### Import errors
- Ensure all dependencies installed: `pip install -r requirements.txt`
- Use Python 3.8+: `python --version`

## Project Structure

```
assistant/
├── main.py                   # Main orchestrator
├── config.py                 # Configuration settings
├── camera_subsystem.py       # Camera + keyframe detection
├── audio_subsystem.py        # VAD + speaker ID + STT
├── ocr_subsystem.py          # Text extraction
├── memory_subsystem.py       # Context management
├── llm_integration.py        # LLM API integration
├── requirements.txt          # Python dependencies
├── .gitignore               # Git ignore rules
├── README.md                # Architecture documentation
└── SETUP.md                 # This file
```

## Next Steps

1. **Add Real LLM Integration**: Configure OpenAI API or other LLM provider
2. **Implement Real STT**: Use Whisper model for speech recognition
3. **Add Speaker Diarization**: Use ECAPA-TDNN for actual speaker identification
4. **Create Mobile App**: Port to iOS/Android using the architecture
5. **Add Vector DB**: Implement semantic search for memory
6. **Optimize Performance**: Profile and optimize keyframe detection

## Support

For issues or questions, check:
- Architecture: See `README.md`
- This setup guide: `SETUP.md`
- Individual module tests: Run each `*_subsystem.py` file directly
