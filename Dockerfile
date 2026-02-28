FROM runpod/worker-comfyui:5.5.1-base

# Install GGUF loader for quantized models (try registry name, then git URL fallback)
RUN comfy-node-install comfyui-gguf || \
    cd /comfyui/custom_nodes && git clone https://github.com/city96/ComfyUI-GGUF.git && \
    cd ComfyUI-GGUF && pip install -r requirements.txt

# Install video helper suite for video output
RUN comfy-node-install comfyui-videohelpersuite || \
    cd /comfyui/custom_nodes && git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    cd ComfyUI-VideoHelperSuite && pip install -r requirements.txt

# Download Wan 2.2 I2V GGUF models (Q4_K_S for better quality, fits 24GB VRAM)
RUN comfy model download \
    --url "https://huggingface.co/QuantStack/Wan2.2-I2V-A14B-GGUF/resolve/main/HighNoise/Wan2.2-I2V-A14B-HighNoise-Q4_K_S.gguf" \
    --relative-path models/diffusion_models \
    --filename Wan2.2-I2V-A14B-HighNoise-Q4_K_S.gguf

RUN comfy model download \
    --url "https://huggingface.co/QuantStack/Wan2.2-I2V-A14B-GGUF/resolve/main/LowNoise/Wan2.2-I2V-A14B-LowNoise-Q4_K_S.gguf" \
    --relative-path models/diffusion_models \
    --filename Wan2.2-I2V-A14B-LowNoise-Q4_K_S.gguf

RUN comfy model download \
    --url "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
    --relative-path models/text_encoders \
    --filename umt5_xxl_fp8_e4m3fn_scaled.safetensors

RUN comfy model download \
    --url "https://huggingface.co/QuantStack/Wan2.2-I2V-A14B-GGUF/resolve/main/VAE/Wan2.1_VAE.safetensors" \
    --relative-path models/vae \
    --filename Wan2.1_VAE.safetensors

RUN comfy model download \
    --url "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" \
    --relative-path models/clip_vision \
    --filename clip_vision_h.safetensors
