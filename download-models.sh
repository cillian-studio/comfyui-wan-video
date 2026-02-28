#!/bin/bash
# Download Wan 2.2 GGUF models to Network Volume
# Run this once on a temporary pod with the volume mounted

MODEL_DIR="${1:-/workspace/models}"

echo "Downloading Wan 2.2 GGUF models to $MODEL_DIR..."

mkdir -p "$MODEL_DIR/diffusion_models"
mkdir -p "$MODEL_DIR/text_encoders"
mkdir -p "$MODEL_DIR/vae"
mkdir -p "$MODEL_DIR/clip_vision"

# Wan 2.2 I2V HighNoise GGUF (Q4_K_S — better quality than Q3)
if [ ! -f "$MODEL_DIR/diffusion_models/Wan2.2-I2V-A14B-HighNoise-Q4_K_S.gguf" ]; then
  echo "Downloading HighNoise model..."
  wget -q --show-progress -O "$MODEL_DIR/diffusion_models/Wan2.2-I2V-A14B-HighNoise-Q4_K_S.gguf" \
    "https://huggingface.co/QuantStack/Wan2.2-I2V-A14B-GGUF/resolve/main/HighNoise/Wan2.2-I2V-A14B-HighNoise-Q4_K_S.gguf"
fi

# Wan 2.2 I2V LowNoise GGUF (Q4_K_S)
if [ ! -f "$MODEL_DIR/diffusion_models/Wan2.2-I2V-A14B-LowNoise-Q4_K_S.gguf" ]; then
  echo "Downloading LowNoise model..."
  wget -q --show-progress -O "$MODEL_DIR/diffusion_models/Wan2.2-I2V-A14B-LowNoise-Q4_K_S.gguf" \
    "https://huggingface.co/QuantStack/Wan2.2-I2V-A14B-GGUF/resolve/main/LowNoise/Wan2.2-I2V-A14B-LowNoise-Q4_K_S.gguf"
fi

# Text encoder (UMT5-XXL fp8)
if [ ! -f "$MODEL_DIR/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" ]; then
  echo "Downloading text encoder..."
  wget -q --show-progress -O "$MODEL_DIR/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
fi

# VAE
if [ ! -f "$MODEL_DIR/vae/Wan2.1_VAE.safetensors" ]; then
  echo "Downloading VAE..."
  wget -q --show-progress -O "$MODEL_DIR/vae/Wan2.1_VAE.safetensors" \
    "https://huggingface.co/QuantStack/Wan2.2-I2V-A14B-GGUF/resolve/main/VAE/Wan2.1_VAE.safetensors"
fi

# CLIP Vision
if [ ! -f "$MODEL_DIR/clip_vision/clip_vision_h.safetensors" ]; then
  echo "Downloading CLIP Vision..."
  wget -q --show-progress -O "$MODEL_DIR/clip_vision/clip_vision_h.safetensors" \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"
fi

echo "All models downloaded!"
ls -lah "$MODEL_DIR"/diffusion_models/
ls -lah "$MODEL_DIR"/text_encoders/
ls -lah "$MODEL_DIR"/vae/
ls -lah "$MODEL_DIR"/clip_vision/
