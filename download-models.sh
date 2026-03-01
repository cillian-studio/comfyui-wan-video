#!/bin/bash
# Run this on a temporary RunPod GPU Pod with Network Volume attached.
# Downloads all LTX-2 + Wan 2.2 models to /runpod-volume/models/
set -e

BASE="/runpod-volume/models"
mkdir -p "$BASE"/{diffusion_models,text_encoders,vae,clip_vision}

echo "=== LTX-2 Models (Video + Audio, ~27GB) ==="

echo "[1/5] LTX-2 GGUF Q4_K_S (~12GB)..."
wget -c -O "$BASE/diffusion_models/ltx-2-19b-dev-Q4_K_S.gguf" \
  "https://huggingface.co/unsloth/LTX-2-GGUF/resolve/main/ltx-2-19b-dev-Q4_K_S.gguf"

echo "[2/5] Gemma 3 12B FP4 Text Encoder (~9.5GB)..."
wget -c -O "$BASE/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors" \
  "https://huggingface.co/Comfy-Org/ltx-2/resolve/main/split_files/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors"

echo "[3/5] Embeddings Connector (~2.9GB)..."
wget -c -O "$BASE/text_encoders/ltx-2-19b-embeddings_connector_dev_bf16.safetensors" \
  "https://huggingface.co/Kijai/LTXV2_comfy/resolve/main/text_encoders/ltx-2-19b-embeddings_connector_dev_bf16.safetensors"

echo "[4/5] Video VAE (~2.5GB)..."
wget -c -O "$BASE/vae/LTX2_video_vae_bf16.safetensors" \
  "https://huggingface.co/Kijai/LTXV2_comfy/resolve/main/VAE/LTX2_video_vae_bf16.safetensors"

echo "[5/5] Audio VAE (~218MB)..."
wget -c -O "$BASE/vae/LTX2_audio_vae_bf16.safetensors" \
  "https://huggingface.co/Kijai/LTXV2_comfy/resolve/main/VAE/LTX2_audio_vae_bf16.safetensors"

echo ""
echo "=== Done ==="
du -sh "$BASE"/*
echo "Total:"
du -sh "$BASE"
