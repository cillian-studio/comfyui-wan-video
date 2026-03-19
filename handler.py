"""
RunPod Serverless Handler — AI Studio
Models: Wan 2.1 (T2V + I2V), LTX-Video (T2V), CogVideoX-5B (T2V)
All downloaded on first request, cached in /tmp/models/
"""

import runpod
import torch
import os
import base64
import time

MODEL_PATH = "/tmp/models"
OUTPUT_PATH = "/tmp/outputs"

loaded_models = {}

GGUF_URLS = {
    "t2v": "https://huggingface.co/city96/Wan2.1-T2V-14B-gguf/resolve/main/wan2.1-t2v-14b-Q4_K_S.gguf",
    "i2v": "https://huggingface.co/city96/Wan2.1-I2V-14B-480P-gguf/resolve/main/wan2.1-i2v-14b-480p-Q4_K_S.gguf",
}

GGUF_FILES = {
    "t2v": "wan2.1-t2v-14b-Q4_K_S.gguf",
    "i2v": "wan2.1-i2v-14b-480p-Q4_K_S.gguf",
}


def ensure_gguf(model_key):
    """Download GGUF model if not already cached."""
    os.makedirs(MODEL_PATH, exist_ok=True)
    path = os.path.join(MODEL_PATH, GGUF_FILES[model_key])
    if not os.path.exists(path):
        url = GGUF_URLS[model_key]
        print(f"Downloading {GGUF_FILES[model_key]}...", flush=True)
        import subprocess
        subprocess.run(["curl", "-L", "-o", path, url], check=True)
        print(f"Downloaded: {os.path.getsize(path)/1e9:.1f} GB", flush=True)
    return path


# ── Wan 2.1 T2V ──

def load_wan_t2v():
    if "wan_t2v" in loaded_models:
        return loaded_models["wan_t2v"]
    from diffusers import WanPipeline, WanTransformer3DModel, GGUFQuantizationConfig
    gguf_path = ensure_gguf("t2v")
    print("Loading Wan 2.1 T2V GGUF...", flush=True)
    transformer = WanTransformer3DModel.from_single_file(
        gguf_path,
        quantization_config=GGUFQuantizationConfig(compute_dtype=torch.bfloat16),
        torch_dtype=torch.bfloat16,
    )
    pipe = WanPipeline.from_pretrained(
        "Wan-AI/Wan2.1-T2V-14B-Diffusers", transformer=transformer, torch_dtype=torch.bfloat16,
    )
    pipe.enable_model_cpu_offload()
    loaded_models["wan_t2v"] = pipe
    print("Wan 2.1 T2V loaded.", flush=True)
    return pipe


def generate_wan_t2v(params):
    pipe = load_wan_t2v()
    from diffusers.utils import export_to_video
    output = pipe(
        prompt=params.get("prompt", ""),
        negative_prompt=params.get("negative_prompt", "") or None,
        width=params.get("width", 832),
        height=params.get("height", 480),
        num_frames=params.get("num_frames", 81),
        num_inference_steps=params.get("steps", 20),
        guidance_scale=params.get("guidance_scale", 5.0),
        generator=torch.Generator("cuda").manual_seed(params["seed"]) if params.get("seed", -1) >= 0 else None,
    )
    return _export_video(output.frames[0], "wan_t2v", 16)


# ── Wan 2.1 I2V ──

def load_wan_i2v():
    if "wan_i2v" in loaded_models:
        return loaded_models["wan_i2v"]
    from diffusers import WanImageToVideoPipeline, WanTransformer3DModel, GGUFQuantizationConfig
    gguf_path = ensure_gguf("i2v")
    print("Loading Wan 2.1 I2V GGUF...", flush=True)
    transformer = WanTransformer3DModel.from_single_file(
        gguf_path,
        quantization_config=GGUFQuantizationConfig(compute_dtype=torch.bfloat16),
        torch_dtype=torch.bfloat16,
    )
    pipe = WanImageToVideoPipeline.from_pretrained(
        "Wan-AI/Wan2.1-I2V-14B-480P-Diffusers", transformer=transformer, torch_dtype=torch.bfloat16,
    )
    pipe.enable_model_cpu_offload()
    loaded_models["wan_i2v"] = pipe
    print("Wan 2.1 I2V loaded.", flush=True)
    return pipe


def generate_wan_i2v(params):
    pipe = load_wan_i2v()
    from diffusers.utils import export_to_video, load_image
    import io
    from PIL import Image

    image_b64 = params.get("image_base64", "")
    image_url = params.get("image", params.get("image_url", ""))
    if image_b64:
        image = Image.open(io.BytesIO(base64.b64decode(image_b64))).convert("RGB")
    elif image_url:
        image = load_image(image_url)
    else:
        return {"error": "image_url or image_base64 required for I2V"}

    w, h = params.get("width", 832), params.get("height", 480)
    image = image.resize((w, h))

    output = pipe(
        image=image,
        prompt=params.get("prompt", ""),
        negative_prompt=params.get("negative_prompt", "") or None,
        width=w, height=h,
        num_frames=params.get("num_frames", 81),
        num_inference_steps=params.get("steps", 20),
        guidance_scale=params.get("guidance_scale", 5.0),
        generator=torch.Generator("cuda").manual_seed(params["seed"]) if params.get("seed", -1) >= 0 else None,
    )
    return _export_video(output.frames[0], "wan_i2v", 16)


# ── LTX-Video ──

def load_ltx():
    if "ltx" in loaded_models:
        return loaded_models["ltx"]
    from diffusers import LTXPipeline, AutoModel
    print("Loading LTX-Video...", flush=True)
    transformer = AutoModel.from_pretrained(
        "Lightricks/LTX-Video", subfolder="transformer", torch_dtype=torch.bfloat16,
    )
    transformer.enable_layerwise_casting(
        storage_dtype=torch.float8_e4m3fn, compute_dtype=torch.bfloat16,
    )
    pipe = LTXPipeline.from_pretrained(
        "Lightricks/LTX-Video", transformer=transformer, torch_dtype=torch.bfloat16,
    )
    pipe.enable_model_cpu_offload()
    loaded_models["ltx"] = pipe
    print("LTX-Video loaded.", flush=True)
    return pipe


def generate_ltx(params):
    pipe = load_ltx()
    from diffusers.utils import export_to_video
    output = pipe(
        prompt=params.get("prompt", ""),
        negative_prompt=params.get("negative_prompt", "worst quality, inconsistent motion, blurry, jittery, distorted"),
        width=params.get("width", 768),
        height=params.get("height", 512),
        num_frames=params.get("num_frames", 97),
        num_inference_steps=params.get("steps", 40),
        decode_timestep=0.03,
        decode_noise_scale=0.025,
        generator=torch.Generator("cuda").manual_seed(params["seed"]) if params.get("seed", -1) >= 0 else None,
    )
    return _export_video(output.frames[0], "ltx", 24)


# ── CogVideoX-5B ──

def load_cogvideo():
    if "cogvideo" in loaded_models:
        return loaded_models["cogvideo"]
    from diffusers import CogVideoXPipeline
    print("Loading CogVideoX-5B...", flush=True)
    pipe = CogVideoXPipeline.from_pretrained(
        "THUDM/CogVideoX-5b", torch_dtype=torch.float16,
    )
    pipe.enable_model_cpu_offload()
    loaded_models["cogvideo"] = pipe
    print("CogVideoX-5B loaded.", flush=True)
    return pipe


def generate_cogvideo(params):
    pipe = load_cogvideo()
    from diffusers.utils import export_to_video
    output = pipe(
        prompt=params.get("prompt", ""),
        guidance_scale=params.get("guidance_scale", 6.0),
        num_inference_steps=params.get("steps", 50),
        use_dynamic_cfg=True,
        generator=torch.Generator("cuda").manual_seed(params["seed"]) if params.get("seed", -1) >= 0 else None,
    )
    return _export_video(output.frames[0], "cogvideo", 8)


# ── Helpers ──

def _export_video(frames, prefix, fps):
    from diffusers.utils import export_to_video
    os.makedirs(OUTPUT_PATH, exist_ok=True)
    video_path = os.path.join(OUTPUT_PATH, f"{prefix}_{int(time.time())}.mp4")
    export_to_video(frames, video_path, fps=fps)
    with open(video_path, "rb") as f:
        video_b64 = base64.b64encode(f.read()).decode("utf-8")
    os.remove(video_path)
    return {"video": video_b64, "format": "mp4", "fps": fps}


# ── Main Handler ──

def handler(event):
    try:
        input_data = event.get("input", {})
        model = input_data.get("model", "wan-t2v")
        params = input_data.get("params", {})
        if not params:
            params = {k: v for k, v in input_data.items() if k != "model"}

        print(f"Request: model={model}", flush=True)

        if model in ("wan-t2v", "wan", "t2v", "text-to-video"):
            return generate_wan_t2v(params)
        elif model in ("wan-i2v", "i2v", "image-to-video"):
            return generate_wan_i2v(params)
        elif model in ("ltx", "ltx-video", "ltx-t2v"):
            return generate_ltx(params)
        elif model in ("cogvideo", "cogvideox", "cogvideo-t2v"):
            return generate_cogvideo(params)
        elif model == "health":
            t2v = os.path.exists(os.path.join(MODEL_PATH, GGUF_FILES["t2v"]))
            i2v = os.path.exists(os.path.join(MODEL_PATH, GGUF_FILES["i2v"]))
            return {
                "status": "ok",
                "models": {
                    "wan-t2v": {"on_disk": t2v, "loaded": "wan_t2v" in loaded_models},
                    "wan-i2v": {"on_disk": i2v, "loaded": "wan_i2v" in loaded_models},
                    "ltx": {"loaded": "ltx" in loaded_models},
                    "cogvideo": {"loaded": "cogvideo" in loaded_models},
                },
                "gpu": torch.cuda.get_device_name(0) if torch.cuda.is_available() else "none",
                "vram_gb": round(torch.cuda.get_device_properties(0).total_memory / 1e9, 1) if torch.cuda.is_available() else 0,
            }
        else:
            return {"error": f"Unknown model: {model}. Available: wan-t2v, wan-i2v, ltx, cogvideo, health"}

    except Exception as e:
        import traceback
        return {"error": str(e), "traceback": traceback.format_exc()}


runpod.serverless.start({"handler": handler})
