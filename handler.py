"""
RunPod Serverless Handler — AI Studio
Models: Wan 2.1 14B GGUF Q4_K_S (T2V + I2V)
Baked into Docker image at /app/models/
"""

import runpod
import torch
import os
import base64
import time

MODEL_PATH = "/app/models"
OUTPUT_PATH = "/tmp/outputs"

loaded_models = {}


def load_wan_t2v():
    """Load Wan 2.1 14B GGUF for text-to-video."""
    if "wan_t2v" in loaded_models:
        return loaded_models["wan_t2v"]

    from diffusers import WanPipeline, WanTransformer3DModel, GGUFQuantizationConfig

    gguf_path = os.path.join(MODEL_PATH, "wan2.1-t2v-14b-Q4_K_S.gguf")
    print(f"Loading Wan 2.1 T2V GGUF...", flush=True)

    transformer = WanTransformer3DModel.from_single_file(
        gguf_path,
        quantization_config=GGUFQuantizationConfig(compute_dtype=torch.bfloat16),
        torch_dtype=torch.bfloat16,
    )
    pipe = WanPipeline.from_pretrained(
        "Wan-AI/Wan2.1-T2V-14B-Diffusers",
        transformer=transformer,
        torch_dtype=torch.bfloat16,
    )
    pipe.enable_model_cpu_offload()

    loaded_models["wan_t2v"] = pipe
    print("Wan 2.1 T2V loaded.", flush=True)
    return pipe


def load_wan_i2v():
    """Load Wan 2.1 14B GGUF for image-to-video."""
    if "wan_i2v" in loaded_models:
        return loaded_models["wan_i2v"]

    from diffusers import WanImageToVideoPipeline, WanTransformer3DModel, GGUFQuantizationConfig

    gguf_path = os.path.join(MODEL_PATH, "wan2.1-i2v-14b-480p-Q4_K_S.gguf")
    print(f"Loading Wan 2.1 I2V GGUF...", flush=True)

    transformer = WanTransformer3DModel.from_single_file(
        gguf_path,
        quantization_config=GGUFQuantizationConfig(compute_dtype=torch.bfloat16),
        torch_dtype=torch.bfloat16,
    )
    pipe = WanImageToVideoPipeline.from_pretrained(
        "Wan-AI/Wan2.1-I2V-14B-480P-Diffusers",
        transformer=transformer,
        torch_dtype=torch.bfloat16,
    )
    pipe.enable_model_cpu_offload()

    loaded_models["wan_i2v"] = pipe
    print("Wan 2.1 I2V loaded.", flush=True)
    return pipe


def generate_t2v(params):
    """Generate video from text prompt."""
    pipe = load_wan_t2v()
    from diffusers.utils import export_to_video

    prompt = params.get("prompt", "")
    negative_prompt = params.get("negative_prompt", "")
    width = params.get("width", 832)
    height = params.get("height", 480)
    num_frames = params.get("num_frames", 81)
    steps = params.get("steps", 30)
    guidance = params.get("guidance_scale", 5.0)
    seed = params.get("seed", -1)

    generator = None
    if seed >= 0:
        generator = torch.Generator("cuda").manual_seed(seed)

    output = pipe(
        prompt=prompt,
        negative_prompt=negative_prompt if negative_prompt else None,
        width=width,
        height=height,
        num_frames=num_frames,
        num_inference_steps=steps,
        guidance_scale=guidance,
        generator=generator,
    )

    os.makedirs(OUTPUT_PATH, exist_ok=True)
    video_path = os.path.join(OUTPUT_PATH, f"t2v_{int(time.time())}.mp4")
    export_to_video(output.frames[0], video_path, fps=16)

    with open(video_path, "rb") as f:
        video_b64 = base64.b64encode(f.read()).decode("utf-8")
    os.remove(video_path)

    return {
        "video": video_b64,
        "format": "mp4",
        "width": width,
        "height": height,
        "num_frames": num_frames,
        "fps": 16,
    }


def generate_i2v(params):
    """Generate video from image + prompt."""
    pipe = load_wan_i2v()
    from diffusers.utils import export_to_video, load_image

    prompt = params.get("prompt", "")
    negative_prompt = params.get("negative_prompt", "")
    image_url = params.get("image", params.get("image_url", ""))
    image_b64 = params.get("image_base64", "")
    width = params.get("width", 832)
    height = params.get("height", 480)
    num_frames = params.get("num_frames", 81)
    steps = params.get("steps", 30)
    guidance = params.get("guidance_scale", 5.0)
    seed = params.get("seed", -1)

    # Load image from URL or base64
    if image_b64:
        import io
        from PIL import Image
        image_data = base64.b64decode(image_b64)
        image = Image.open(io.BytesIO(image_data)).convert("RGB")
    elif image_url:
        image = load_image(image_url)
    else:
        return {"error": "image_url or image_base64 required for I2V"}

    image = image.resize((width, height))

    generator = None
    if seed >= 0:
        generator = torch.Generator("cuda").manual_seed(seed)

    output = pipe(
        image=image,
        prompt=prompt,
        negative_prompt=negative_prompt if negative_prompt else None,
        width=width,
        height=height,
        num_frames=num_frames,
        num_inference_steps=steps,
        guidance_scale=guidance,
        generator=generator,
    )

    os.makedirs(OUTPUT_PATH, exist_ok=True)
    video_path = os.path.join(OUTPUT_PATH, f"i2v_{int(time.time())}.mp4")
    export_to_video(output.frames[0], video_path, fps=16)

    with open(video_path, "rb") as f:
        video_b64 = base64.b64encode(f.read()).decode("utf-8")
    os.remove(video_path)

    return {
        "video": video_b64,
        "format": "mp4",
        "width": width,
        "height": height,
        "num_frames": num_frames,
        "fps": 16,
    }


def handler(event):
    """Main handler — routes T2V and I2V."""
    try:
        input_data = event.get("input", {})
        model = input_data.get("model", "wan-t2v")
        params = input_data.get("params", {})
        if not params:
            params = {k: v for k, v in input_data.items() if k != "model"}

        print(f"Request: model={model}", flush=True)

        if model in ("wan-t2v", "wan", "t2v", "video", "text-to-video"):
            return generate_t2v(params)
        elif model in ("wan-i2v", "i2v", "image-to-video"):
            return generate_i2v(params)
        elif model == "health":
            t2v_exists = os.path.exists(os.path.join(MODEL_PATH, "wan2.1-t2v-14b-Q4_K_S.gguf"))
            i2v_exists = os.path.exists(os.path.join(MODEL_PATH, "wan2.1-i2v-14b-480p-Q4_K_S.gguf"))
            return {
                "status": "ok",
                "models": {
                    "t2v": {"on_disk": t2v_exists, "loaded": "wan_t2v" in loaded_models},
                    "i2v": {"on_disk": i2v_exists, "loaded": "wan_i2v" in loaded_models},
                },
                "gpu": torch.cuda.get_device_name(0) if torch.cuda.is_available() else "none",
                "vram_gb": round(torch.cuda.get_device_properties(0).total_memory / 1e9, 1) if torch.cuda.is_available() else 0,
            }
        else:
            return {"error": f"Unknown model: {model}. Available: wan-t2v, wan-i2v, health"}

    except Exception as e:
        import traceback
        return {"error": str(e), "traceback": traceback.format_exc()}


runpod.serverless.start({"handler": handler})
