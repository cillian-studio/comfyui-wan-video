#!/bin/bash
# Symlink models from Network Volume into ComfyUI model directories
VOLUME="/runpod-volume/models"

if [ -d "$VOLUME" ]; then
    echo "Network Volume found — symlinking models..."
    for dir in diffusion_models text_encoders vae clip_vision; do
        if [ -d "$VOLUME/$dir" ]; then
            for f in "$VOLUME/$dir"/*; do
                [ -f "$f" ] && ln -sf "$f" "/comfyui/models/$dir/$(basename "$f")" && echo "  Linked: $dir/$(basename "$f")"
            done
        fi
    done
    echo "Model symlinks created."
else
    echo "WARNING: No Network Volume at $VOLUME — models must be baked into image!"
fi

# Start the original ComfyUI worker
exec /start.sh
