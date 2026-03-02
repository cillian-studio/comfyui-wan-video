#!/bin/bash
# Run this on a temporary RunPod GPU Pod with Network Volume attached.
# Downloads all LTX-2 fp8 models to /runpod-volume/models/
# NOTE: start.sh does this automatically on first serverless boot.
set -e

BASE="/runpod-volume/models"
mkdir -p "$BASE"/{checkpoints,text_encoders,loras}

echo "=== Cleaning old GGUF models ==="
rm -f "$BASE/diffusion_models/ltx-2-19b-dev-Q4_K_S.gguf"
rm -f "$BASE/checkpoints/ltx-2-19b-embeddings_connector_dev_bf16.safetensors"
rm -f "$BASE/vae/LTX2_video_vae_bf16.safetensors"
rm -f "$BASE/vae/LTX2_audio_vae_bf16.safetensors"
rm -f "$BASE/unet/ltx-2-19b-dev-Q4_K_S.gguf"
rm -f "$BASE/.ltx2-complete"

echo "=== LTX-2 fp8 Models (~37GB total) ==="

echo "[1/3] LTX-2 Distilled fp8 Checkpoint (~27GB)..."
wget -c -O "$BASE/checkpoints/ltx-2-19b-distilled-fp8.safetensors" \
  "https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-19b-distilled-fp8.safetensors"

echo "[2/3] Gemma 3 12B FP4 Text Encoder (~9.5GB)..."
wget -c -O "$BASE/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors" \
  "https://huggingface.co/Comfy-Org/ltx-2/resolve/main/split_files/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors"

echo "[3/3] Distilled LoRA (rank-384, ~7.7GB)..."
wget -c -O "$BASE/loras/ltx-2-19b-distilled-lora-384.safetensors" \
  "https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-19b-distilled-lora-384.safetensors"

touch "$BASE/.ltx2-fp8-complete"

echo ""
echo "=== Done ==="
du -sh "$BASE"/* 2>/dev/null || true
echo "Total:"
du -sh "$BASE"
