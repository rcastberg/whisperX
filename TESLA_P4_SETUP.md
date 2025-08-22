# WhisperX Tesla P4 GPU Setup

This setup is specifically optimized for Tesla P4 GPU compatibility. The Tesla P4 is an older GPU that requires specific CUDA versions and package compatibility.

## Prerequisites

1. **NVIDIA Drivers**: Ensure you have NVIDIA drivers installed (version 450.80.02 or higher)
2. **Docker**: Install Docker and Docker Compose
3. **NVIDIA Container Toolkit**: Install nvidia-docker2

### Install NVIDIA Container Toolkit

```bash
# Add NVIDIA package repositories
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Install nvidia-docker2
sudo apt-get update
sudo apt-get install -y nvidia-docker2

# Restart Docker daemon
sudo systemctl restart docker
```

## Quick Start

### 1. Build the Docker Image

```bash
# Build the Tesla P4 optimized image
docker build -t whisperx-tesla-p4 .
```

### 2. Create Directories

```bash
# Create directories for videos and output
mkdir -p videos output
```

### 3. Run with Docker

#### Option A: Using Docker Run

```bash
# Place your video files in the videos directory
# Then run the container
docker run --gpus all -v $(pwd)/videos:/app/videos -v $(pwd)/output:/app/output whisperx-tesla-p4 your_video.mp4
```

#### Option B: Using Docker Compose

```bash
# Build and run with docker-compose
docker-compose up --build

# To process a specific video
docker-compose run whisperx your_video.mp4
```

## Usage Examples

### Basic Transcription

```bash
# Process a video file
docker run --gpus all -v $(pwd)/videos:/app/videos -v $(pwd)/output:/app/output whisperx-tesla-p4 video.mp4
```

### Advanced Options

```bash
# Use large model with specific settings for Tesla P4
docker run --gpus all -v $(pwd)/videos:/app/videos -v $(pwd)/output:/app/output whisperx-tesla-p4 video.mp4 --model large-v2 --compute_type float16 --batch_size 4
```

### With Speaker Diarization

```bash
# Add speaker diarization (requires Hugging Face token)
docker run --gpus all -v $(pwd)/videos:/app/videos -v $(pwd)/output:/app/output whisperx-tesla-p4 video.mp4 --diarize --hf_token YOUR_HF_TOKEN
```

## Tesla P4 Optimizations

The setup includes several optimizations for Tesla P4:

1. **CUDA 11.8**: Compatible with Tesla P4 architecture
2. **PyTorch 2.0.1**: Stable version with good Tesla P4 support
3. **Float16**: Default compute type to reduce memory usage
4. **Batch Size 4**: Conservative batch size for 8GB VRAM
5. **Older Package Versions**: Compatible with Tesla P4's compute capabilities

## Memory Management

Tesla P4 has 8GB VRAM. To optimize memory usage:

- Use `--compute_type float16` (default in this setup)
- Use `--batch_size 4` or lower
- Use smaller models like `--model base` or `--model small` if needed
- Close other GPU applications

## Troubleshooting

### CUDA Version Issues

If you encounter CUDA version errors:

```bash
# Check CUDA version in container
docker run --gpus all whisperx-tesla-p4 nvidia-smi

# Check PyTorch CUDA support
docker run --gpus all whisperx-tesla-p4 python -c "import torch; print(torch.cuda.is_available())"
```

### Memory Issues

If you get out-of-memory errors:

```bash
# Use smaller model and batch size
docker run --gpus all -v $(pwd)/videos:/app/videos whisperx-tesla-p4 video.mp4 --model base --batch_size 2 --compute_type int8
```

### Audio Format Issues

If you have audio format problems:

```bash
# Convert video to compatible format first
ffmpeg -i input.mp4 -c:v libx264 -c:a aac -strict experimental output.mp4
```

## Performance Notes

- Tesla P4 is optimized for inference, not training
- Expect ~10-20x real-time speed with large-v2 model
- Use `--compute_type int8` for maximum speed (may reduce accuracy)
- Speaker diarization will be slower on Tesla P4

## File Structure

```
.
├── Dockerfile              # Tesla P4 optimized Dockerfile
├── docker-compose.yml      # Docker Compose configuration
├── pyproject.toml          # Updated dependencies for Tesla P4
├── requirements.txt        # Alternative requirements file
├── videos/                 # Place your video files here
└── output/                 # Transcribed files will appear here
```

## Supported Video Formats

- MP4, AVI, MOV, MKV, WebM
- Audio: MP3, WAV, FLAC, M4A
- Video codecs: H.264, H.265, VP9
- Audio codecs: AAC, MP3, PCM

## Output Formats

The container will generate:
- `.srt` subtitle files
- `.json` detailed transcription data
- `.txt` plain text transcription
- `.vtt` WebVTT subtitles
