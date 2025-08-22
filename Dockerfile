# Use NVIDIA CUDA 11.8 base image for Tesla P4 compatibility
FROM nvidia/cuda:11.8.0-devel-ubuntu20.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CUDA_VISIBLE_DEVICES=0

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.9 \
    python3.9-dev \
    python3-pip \
    git \
    wget \
    curl \
    ffmpeg \
    libsndfile1 \
    libportaudio2 \
    portaudio19-dev \
    build-essential \
    cmake \
    pkg-config \
    libcudnn8 \
    libcudnn8-dev \
    libcublas-11-8 \
    libcublas-dev-11-8 \
    && rm -rf /var/lib/apt/lists/*

# Create symbolic link for python
RUN ln -s /usr/bin/python3.9 /usr/bin/python

# Upgrade pip
RUN python -m pip install --upgrade pip

# Install PyTorch with CUDA 11.8 support (compatible with Tesla P4)
RUN pip install torch==2.0.1+cu118 torchaudio==2.0.2+cu118 --index-url https://download.pytorch.org/whl/cu118

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt ./
COPY pyproject.toml ./
COPY whisperx/ ./whisperx/

# Install dependencies with pip
RUN pip install -r requirements.txt
RUN pip install -e .

# Download NLTK data
RUN python -c "import nltk; nltk.download('punkt')"

#--compute_type float32 --batch_size 2
ENTRYPOINT ["whisperx"]
