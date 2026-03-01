#!/bin/bash
# Auto-download LTX-2 models to Network Volume on first boot, then symlink into ComfyUI.
set -e

VOLUME="/runpod-volume/models"
MARKER="$VOLUME/.ltx2-complete"

# ── Step 1: Download models if not already on volume ──
if [ -d "/runpod-volume" ] && [ ! -f "$MARKER" ]; then
    echo "=== First boot: downloading LTX-2 models to Network Volume (~27GB) ==="
    mkdir -p "$VOLUME"/{diffusion_models,text_encoders,vae,clip_vision,checkpoints}

    echo "[1/5] LTX-2 GGUF Q4_K_S (~12GB)..."
    wget -q --show-progress -c -O "$VOLUME/diffusion_models/ltx-2-19b-dev-Q4_K_S.gguf" \
      "https://huggingface.co/unsloth/LTX-2-GGUF/resolve/main/ltx-2-19b-dev-Q4_K_S.gguf"

    echo "[2/5] Gemma 3 12B FP4 Text Encoder (~9.5GB)..."
    wget -q --show-progress -c -O "$VOLUME/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors" \
      "https://huggingface.co/Comfy-Org/ltx-2/resolve/main/split_files/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors"

    echo "[3/5] Embeddings Connector (~2.9GB)..."
    wget -q --show-progress -c -O "$VOLUME/checkpoints/ltx-2-19b-embeddings_connector_dev_bf16.safetensors" \
      "https://huggingface.co/Kijai/LTXV2_comfy/resolve/main/text_encoders/ltx-2-19b-embeddings_connector_dev_bf16.safetensors"

    echo "[4/5] Video VAE (~2.5GB)..."
    wget -q --show-progress -c -O "$VOLUME/vae/LTX2_video_vae_bf16.safetensors" \
      "https://huggingface.co/Kijai/LTXV2_comfy/resolve/main/VAE/LTX2_video_vae_bf16.safetensors"

    echo "[5/5] Audio VAE (~218MB)..."
    wget -q --show-progress -c -O "$VOLUME/vae/LTX2_audio_vae_bf16.safetensors" \
      "https://huggingface.co/Kijai/LTXV2_comfy/resolve/main/VAE/LTX2_audio_vae_bf16.safetensors"

    touch "$MARKER"
    echo "=== All LTX-2 models downloaded ==="
    du -sh "$VOLUME"/*
elif [ -f "$MARKER" ]; then
    echo "Models already on Network Volume."
else
    echo "WARNING: No Network Volume at /runpod-volume!"
fi

# ── Step 2: Symlink models into ComfyUI directories ──
if [ -d "$VOLUME" ]; then
    echo "Symlinking models into ComfyUI..."
    for dir in diffusion_models text_encoders vae clip_vision checkpoints; do
        mkdir -p "/comfyui/models/$dir"
        if [ -d "$VOLUME/$dir" ]; then
            for f in "$VOLUME/$dir"/*; do
                [ -f "$f" ] && ln -sf "$f" "/comfyui/models/$dir/$(basename "$f")" && echo "  Linked: $dir/$(basename "$f")"
            done
        fi
    done

    # Cross-directory symlinks for node compatibility
    # UnetLoaderGGUF may scan unet/ instead of diffusion_models/
    mkdir -p /comfyui/models/unet
    [ -f "$VOLUME/diffusion_models/ltx-2-19b-dev-Q4_K_S.gguf" ] && \
        ln -sf "$VOLUME/diffusion_models/ltx-2-19b-dev-Q4_K_S.gguf" "/comfyui/models/unet/ltx-2-19b-dev-Q4_K_S.gguf"

    # LTXVAudioVAELoader may look in checkpoints/
    [ -f "$VOLUME/vae/LTX2_audio_vae_bf16.safetensors" ] && \
        ln -sf "$VOLUME/vae/LTX2_audio_vae_bf16.safetensors" "/comfyui/models/checkpoints/LTX2_audio_vae_bf16.safetensors"

    echo "Model symlinks created."
fi

# ── Step 3: Start the original ComfyUI worker ──
exec /start.sh
