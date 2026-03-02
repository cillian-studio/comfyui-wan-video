FROM runpod/worker-comfyui:main-base

# Install LTX-2 official nodes (I2V + native audio generation)
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/Lightricks/ComfyUI-LTXVideo.git && \
    cd ComfyUI-LTXVideo && pip install -r requirements.txt && \
    echo "ComfyUI-LTXVideo installed OK"

# Copy startup script (auto-downloads models to Network Volume on first boot)
COPY start.sh /custom-start.sh
RUN chmod +x /custom-start.sh

# Models auto-downloaded to Network Volume on first boot (~37GB)
CMD ["/custom-start.sh"]
