"""Lastscrew packaging-vision Truss.

Wraps Qwen2-VL-7B-Instruct so it accepts the exact OpenAI-style chat-completion
payload our Cloudflare Worker sends — messages with `image_url` content blocks
carrying a base64 JPEG. Returns an OpenAI-style chat completion response.

The Worker's prompt instructs the model to score the photo against a fixed
checklist and emit strict JSON. This Truss just runs inference and returns the
text; JSON parsing happens back in the Worker.
"""

from __future__ import annotations

import base64
import io
import re
from typing import Any

import torch
from PIL import Image
from transformers import AutoProcessor, Qwen2VLForConditionalGeneration

MODEL_ID = "Qwen/Qwen2-VL-7B-Instruct"
DATA_URL_RE = re.compile(r"^data:image/[A-Za-z0-9.+-]+;base64,(.+)$")


class Model:
    def __init__(self, **kwargs: Any) -> None:
        self._model: Qwen2VLForConditionalGeneration | None = None
        self._processor: AutoProcessor | None = None

    def load(self) -> None:
        self._processor = AutoProcessor.from_pretrained(MODEL_ID, trust_remote_code=True)
        self._model = Qwen2VLForConditionalGeneration.from_pretrained(
            MODEL_ID,
            torch_dtype=torch.bfloat16,
            device_map="auto",
            trust_remote_code=True,
        )
        self._model.eval()

    def predict(self, request: dict[str, Any]) -> dict[str, Any]:
        assert self._model is not None and self._processor is not None, "Model not loaded"

        messages_in = request.get("messages") or []
        max_tokens = int(request.get("max_tokens", 600))
        temperature = float(request.get("temperature", 0.1))

        qwen_messages: list[dict[str, Any]] = []
        all_images: list[Image.Image] = []
        for msg in messages_in:
            role = msg.get("role", "user")
            content = msg.get("content", "")
            parts: list[dict[str, Any]] = []
            if isinstance(content, str):
                parts.append({"type": "text", "text": content})
            elif isinstance(content, list):
                for block in content:
                    btype = block.get("type")
                    if btype == "text":
                        parts.append({"type": "text", "text": block.get("text", "")})
                    elif btype == "image_url":
                        url = (block.get("image_url") or {}).get("url", "")
                        img = _decode_image(url)
                        if img is not None:
                            all_images.append(img)
                            parts.append({"type": "image"})
            qwen_messages.append({"role": role, "content": parts})

        prompt = self._processor.apply_chat_template(
            qwen_messages,
            tokenize=False,
            add_generation_prompt=True,
        )

        inputs = self._processor(
            text=[prompt],
            images=all_images if all_images else None,
            padding=True,
            return_tensors="pt",
        ).to(self._model.device)

        with torch.no_grad():
            output_ids = self._model.generate(
                **inputs,
                max_new_tokens=max_tokens,
                temperature=max(temperature, 1e-3),
                do_sample=temperature > 0.05,
            )

        prompt_len = inputs.input_ids.shape[1]
        gen_only = output_ids[:, prompt_len:]
        text = self._processor.batch_decode(
            gen_only,
            skip_special_tokens=True,
            clean_up_tokenization_spaces=False,
        )[0].strip()

        return {
            "id": "chatcmpl-lastscrew-vision",
            "object": "chat.completion",
            "model": MODEL_ID,
            "choices": [
                {
                    "index": 0,
                    "message": {"role": "assistant", "content": text},
                    "finish_reason": "stop",
                }
            ],
            "usage": {
                "prompt_tokens": int(prompt_len),
                "completion_tokens": int(gen_only.shape[1]),
                "total_tokens": int(output_ids.shape[1]),
            },
        }


def _decode_image(url: str) -> Image.Image | None:
    """Decode a `data:image/...;base64,…` URL into a PIL Image. Returns None on parse failure."""
    if not url:
        return None
    m = DATA_URL_RE.match(url)
    if m:
        try:
            raw = base64.b64decode(m.group(1))
            return Image.open(io.BytesIO(raw)).convert("RGB")
        except Exception:
            return None
    # If it's not a data URL we deliberately ignore it — the Worker only sends
    # data URLs for the packaging-photo path.
    return None
