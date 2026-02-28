FROM runpod/worker-comfyui:main-base

# Install GGUF loader for quantized models
RUN comfy-node-install comfyui-gguf

# Install video helper suite for video output
RUN comfy-node-install comfyui-videohelpersuite

# Model download script — runs on first start, models persist on Network Volume
COPY download-models.sh /opt/download-models.sh
RUN chmod +x /opt/download-models.sh
