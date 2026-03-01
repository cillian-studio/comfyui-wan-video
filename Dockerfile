FROM runpod/worker-comfyui:5.5.1-base

# Install LTX-2 official nodes (audio+video generation)
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/Lightricks/ComfyUI-LTXVideo.git && \
    cd ComfyUI-LTXVideo && pip install -r requirements.txt && \
    echo "ComfyUI-LTXVideo installed OK"

# Install GGUF loader for quantized models
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/city96/ComfyUI-GGUF.git && \
    cd ComfyUI-GGUF && pip install -r requirements.txt && \
    echo "ComfyUI-GGUF installed OK"

# Install KJNodes (required for LTX-2 VAE loading)
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/kijai/ComfyUI-KJNodes.git && \
    cd ComfyUI-KJNodes && pip install -r requirements.txt && \
    echo "ComfyUI-KJNodes installed OK"

# Install VideoHelperSuite for video output
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    cd ComfyUI-VideoHelperSuite && pip install -r requirements.txt && \
    echo "VideoHelperSuite installed OK"

# Models loaded from Network Volume at /runpod-volume/
# Volume setup script: see download-models.sh
