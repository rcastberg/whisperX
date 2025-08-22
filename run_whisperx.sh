#!/bin/bash

# WhisperX Tesla P4 Runner Script
# This script makes it easy to run WhisperX with Tesla P4 GPU support

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Check if NVIDIA Docker is available
check_nvidia_docker() {
    if ! docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu20.04 nvidia-smi > /dev/null 2>&1; then
        print_warning "NVIDIA Docker support not detected. GPU acceleration may not work."
        print_warning "Make sure you have nvidia-docker2 installed and configured."
    else
        print_status "NVIDIA Docker support detected."
    fi
}

# Build the Docker image if it doesn't exist
build_image() {
    if ! docker image inspect whisperx-tesla-p4 > /dev/null 2>&1; then
        print_status "Building WhisperX Tesla P4 Docker image..."
        docker build -t whisperx-tesla-p4 .
        print_status "Docker image built successfully."
    else
        print_status "Docker image already exists."
    fi
}

# Create necessary directories
setup_directories() {
    mkdir -p videos output
    print_status "Directories created: videos/ and output/"
}

# Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] <video_file>"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -m, --model         Whisper model (default: large-v2)"
    echo "  -b, --batch-size    Batch size (default: 4)"
    echo "  -c, --compute-type  Compute type (default: float16)"
    echo "  -d, --diarize       Enable speaker diarization"
    echo "  -t, --hf-token      Hugging Face token for diarization"
    echo "  -l, --language      Language code (e.g., en, de, fr)"
    echo "  -o, --output-dir    Output directory (default: output/)"
    echo ""
    echo "Examples:"
    echo "  $0 video.mp4"
    echo "  $0 -m large-v2 -b 4 video.mp4"
    echo "  $0 -d -t YOUR_HF_TOKEN video.mp4"
    echo "  $0 -l de video.mp4"
}

# Main function
main() {
    # Parse command line arguments
    MODEL="large-v2"
    BATCH_SIZE="4"
    COMPUTE_TYPE="float16"
    DIARIZE=false
    HF_TOKEN=""
    LANGUAGE=""
    OUTPUT_DIR="output"
    VIDEO_FILE=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -m|--model)
                MODEL="$2"
                shift 2
                ;;
            -b|--batch-size)
                BATCH_SIZE="$2"
                shift 2
                ;;
            -c|--compute-type)
                COMPUTE_TYPE="$2"
                shift 2
                ;;
            -d|--diarize)
                DIARIZE=true
                shift
                ;;
            -t|--hf-token)
                HF_TOKEN="$2"
                shift 2
                ;;
            -l|--language)
                LANGUAGE="$2"
                shift 2
                ;;
            -o|--output-dir)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -*)
                print_error "Unknown option $1"
                show_usage
                exit 1
                ;;
            *)
                VIDEO_FILE="$1"
                shift
                ;;
        esac
    done

    # Check if video file is provided
    if [[ -z "$VIDEO_FILE" ]]; then
        print_error "No video file specified."
        show_usage
        exit 1
    fi

    # Check if video file exists
    if [[ ! -f "videos/$VIDEO_FILE" ]]; then
        print_error "Video file 'videos/$VIDEO_FILE' not found."
        print_status "Please place your video file in the videos/ directory."
        print_status "Current files in videos/ directory:"
        ls -la videos/ 2>/dev/null || echo "Directory is empty"
        exit 1
    fi

    # Setup
    check_docker
    check_nvidia_docker
    build_image
    setup_directories

    # Build whisperx command
    WHISPERX_CMD="whisperx videos/$VIDEO_FILE --model $MODEL --batch_size $BATCH_SIZE --compute_type $COMPUTE_TYPE"

    if [[ -n "$LANGUAGE" ]]; then
        WHISPERX_CMD="$WHISPERX_CMD --language $LANGUAGE"
    fi

    if [[ "$DIARIZE" == true ]]; then
        WHISPERX_CMD="$WHISPERX_CMD --diarize"
        if [[ -n "$HF_TOKEN" ]]; then
            WHISPERX_CMD="$WHISPERX_CMD --hf_token $HF_TOKEN"
        else
            print_warning "Diarization enabled but no HF token provided. Some features may not work."
        fi
    fi

    # Run the container
    print_status "Running WhisperX with Tesla P4 GPU support..."
    print_status "Command: $WHISPERX_CMD"
    echo ""

    docker run --rm --gpus all \
        -v "$(pwd)/videos:/app/videos" \
        -v "$(pwd)/$OUTPUT_DIR:/app/output" \
        whisperx-tesla-p4 \
        bash -c "cd /app && $WHISPERX_CMD"

    print_status "Transcription completed! Check the $OUTPUT_DIR/ directory for results."
}

# Run main function with all arguments
main "$@"
