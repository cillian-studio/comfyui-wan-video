#!/bin/bash
# Auto-download LTX-2 fp8 models to Network Volume on first boot, then symlink into ComfyUI.
set -e

VOLUME="/runpod-volume/models"
MARKER="$VOLUME/.ltx2-fp8-complete"

# ── Step 1: Download fp8 models if not already on volume ──
if [ -d "/runpod-volume" ] && [ ! -f "$MARKER" ]; then
    echo "=== First boot: downloading LTX-2 fp8 models to Network Volume (~37GB) ==="
    mkdir -p "$VOLUME"/{checkpoints,text_encoders,loras}

    # Clean up old GGUF models to free space
    echo "Cleaning old GGUF models..."
    rm -f "$VOLUME/diffusion_models/ltx-2-19b-dev-Q4_K_S.gguf"
    rm -f "$VOLUME/checkpoints/ltx-2-19b-embeddings_connector_dev_bf16.safetensors"
    rm -f "$VOLUME/vae/LTX2_video_vae_bf16.safetensors"
    rm -f "$VOLUME/vae/LTX2_audio_vae_bf16.safetensors"
    rm -f "$VOLUME/unet/ltx-2-19b-dev-Q4_K_S.gguf"
    rm -f "$VOLUME/.ltx2-complete"

    echo "[1/3] LTX-2 Distilled fp8 Checkpoint (~27GB)..."
    wget -q --show-progress -c -O "$VOLUME/checkpoints/ltx-2-19b-distilled-fp8.safetensors" \
      "https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-19b-distilled-fp8.safetensors"

    # Gemma text encoder — check if already exists from old setup
    if [ ! -f "$VOLUME/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors" ]; then
        echo "[2/3] Gemma 3 12B FP4 Text Encoder (~9.5GB)..."
        wget -q --show-progress -c -O "$VOLUME/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors" \
          "https://huggingface.co/Comfy-Org/ltx-2/resolve/main/split_files/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors"
    else
        echo "[2/3] Gemma 3 text encoder already on volume — skipping."
    fi

    echo "[3/3] Distilled LoRA (rank-384, ~7.7GB)..."
    wget -q --show-progress -c -O "$VOLUME/loras/ltx-2-19b-distilled-lora-384.safetensors" \
      "https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-19b-distilled-lora-384.safetensors"

    touch "$MARKER"
    echo "=== All LTX-2 fp8 models downloaded ==="
    du -sh "$VOLUME"/* 2>/dev/null || true
elif [ -f "$MARKER" ]; then
    echo "LTX-2 fp8 models already on Network Volume."
else
    echo "WARNING: No Network Volume at /runpod-volume!"
fi

# ── Step 2: Symlink models into ComfyUI directories ──
if [ -d "$VOLUME" ]; then
    echo "Symlinking models into ComfyUI..."
    for dir in checkpoints text_encoders loras; do
        mkdir -p "/comfyui/models/$dir"
        if [ -d "$VOLUME/$dir" ]; then
            for f in "$VOLUME/$dir"/*; do
                [ -f "$f" ] && ln -sf "$f" "/comfyui/models/$dir/$(basename "$f")" && echo "  Linked: $dir/$(basename "$f")"
            done
        fi
    done
    echo "Model symlinks created."
fi

# ── Step 3: Start the original ComfyUI worker ──
echo "Starting ComfyUI worker..."
exec /start.sh
