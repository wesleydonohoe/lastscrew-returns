// Baseten client for packaging QA.
//
// We talk to a Baseten-hosted model via its OpenAI-compatible endpoint:
//   POST https://model-<id>.api.baseten.co/environments/production/sync/v1/chat/completions
// The "build your first model" Truss path
// (https://docs.baseten.co/development/model/build-your-first-model) compiles
// a HuggingFace text model into this endpoint with no Python code.
//
// For vision QA we ideally want a multimodal model (Qwen2-VL, LLaVA-NeXT, …),
// which needs a Python-based Truss. The endpoint shape is the same; the
// payload just adds image content blocks. If the deployed model is text-only,
// we use the user-provided photo description as the input and the model
// reasons over that.
//
// If BASETEN_API_KEY / BASETEN_MODEL_ID is missing, we return a deterministic
// mock so the demo runs cold.

export interface PackagingChecklistItem {
  label: string;
  passed: boolean;
  detail?: string;
}

export interface PackagingQAResult {
  verdict: "pass" | "needs_work" | "fail";
  score: number; // 0..1
  checklist: PackagingChecklistItem[];
  notes: string;
  bonusMultiplier: number; // 0..1.2 — modulates the resale bounty
  source: "baseten" | "mock";
}

const QA_PROMPT = `You are a packaging quality inspector for Wayfair's "Last Screw" return program.
The user has dismantled a furniture item and repackaged it into a shippable box — the same job a Wayfair warehouse worker would do on intake. You are deciding whether the package is ready to ship to a buyer (or back to the FC) without further handling.

Score whether the packaging is shippable. Check each item:
1. Item fully dismantled into shippable parts (no oversized assemblies left)
2. Each part wrapped (blanket / shrink / original wrap)
3. Corners and edges padded
4. Original box OR comparable rigid container
5. Box closed and taped on both top and bottom seams
6. Shipping label area clear and dry
7. No visible damage, stains, or wet spots

Return STRICT JSON only — no prose, no backticks — with this exact shape:
{
  "verdict": "pass" | "needs_work" | "fail",
  "score": <0..1>,
  "checklist": [{"label": "...", "passed": true|false, "detail": "..."}],
  "notes": "<one short paragraph>",
  "bonusMultiplier": <0..1.2>
}`;

const DEFAULT_MODEL_NAME = "lastscrew-packaging-vision";

export type BasetenEndpointKind = "predict" | "openai";

export async function runPackagingQA(args: {
  imageBase64?: string;
  imageUrl?: string;
  photoDescription?: string;
  baseteenApiKey?: string;
  basetenModelId?: string;
  basetenModelName?: string;
  /** "predict" = Python Truss /production/predict. "openai" = trt_llm config-only. Default predict. */
  basetenEndpoint?: BasetenEndpointKind;
}): Promise<PackagingQAResult> {
  const { imageBase64, imageUrl, photoDescription } = args;
  const apiKey = args.baseteenApiKey;
  const modelId = args.basetenModelId;
  const modelName = args.basetenModelName ?? DEFAULT_MODEL_NAME;
  const endpointKind: BasetenEndpointKind = args.basetenEndpoint ?? "predict";

  if (!apiKey || !modelId) {
    return mockQA(photoDescription ?? "(no description)");
  }

  // Endpoint depends on how the model was deployed:
  //   • Python Truss with model.py  → /production/predict           (used by lastscrew-packaging-vision)
  //   • trt_llm config-only         → /environments/production/sync/v1/chat/completions
  const url =
    endpointKind === "openai"
      ? `https://model-${modelId}.api.baseten.co/environments/production/sync/v1/chat/completions`
      : `https://model-${modelId}.api.baseten.co/production/predict`;

  const userContent: unknown[] = [];
  // Vision content (only meaningful if the deployed model is multimodal).
  if (imageBase64) {
    userContent.push({
      type: "image_url",
      image_url: { url: `data:image/jpeg;base64,${imageBase64}` },
    });
  }
  if (imageUrl) {
    userContent.push({ type: "image_url", image_url: { url: imageUrl } });
  }
  if (photoDescription) {
    userContent.push({
      type: "text",
      text: `Photo description: ${photoDescription}`,
    });
  }
  // If only an image was provided and the model happens to be text-only,
  // give it a deterministic stub description so it still produces useful JSON.
  if (userContent.length === 0) {
    userContent.push({
      type: "text",
      text: "No description supplied — assume an average attempt at packaging.",
    });
  }

  const messages = [
    { role: "system", content: QA_PROMPT },
    { role: "user", content: userContent },
  ];

  // The OpenAI-compatible endpoint requires a `model` field; the Python
  // Truss endpoint ignores it but accepting both keeps the body shape stable.
  const body =
    endpointKind === "openai"
      ? { model: modelName, messages, max_tokens: 600, temperature: 0.1 }
      : { messages, max_tokens: 600, temperature: 0.1 };

  const response = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Api-Key ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const text = await response.text().catch(() => "");
    throw new Error(
      `Baseten returned ${response.status}: ${text.slice(0, 200)}`,
    );
  }

  const payload = (await response.json()) as {
    choices?: Array<{ message?: { content?: string } }>;
    output?: string;
    content?: string;
  };

  const text =
    payload.choices?.[0]?.message?.content ?? payload.output ?? payload.content ?? "";
  const parsed = parseQA(text);
  return { ...parsed, source: "baseten" };
}

function parseQA(raw: string): Omit<PackagingQAResult, "source"> {
  const start = raw.indexOf("{");
  const end = raw.lastIndexOf("}");
  const json = start !== -1 && end > start ? raw.slice(start, end + 1) : raw;
  const data = JSON.parse(json) as Omit<PackagingQAResult, "source">;
  return {
    verdict: data.verdict ?? "needs_work",
    score: typeof data.score === "number" ? data.score : 0.5,
    checklist: Array.isArray(data.checklist) ? data.checklist : [],
    notes: typeof data.notes === "string" ? data.notes : "",
    bonusMultiplier:
      typeof data.bonusMultiplier === "number" ? data.bonusMultiplier : 1.0,
  };
}

function mockQA(description: string): PackagingQAResult {
  const positive = /(wrapped|taped|padded|box|label|dry|clean)/i.test(description);
  const negative = /(torn|wet|damage|stain|open|missing|no box)/i.test(description);

  if (negative) {
    return {
      verdict: "fail",
      score: 0.32,
      checklist: [
        { label: "Item fully wrapped", passed: false, detail: "Wrap appears torn" },
        { label: "Corners and edges padded", passed: false },
        { label: "Original box or rigid container", passed: false },
        { label: "Box closed and taped", passed: false },
        { label: "Label area clear and dry", passed: false },
        { label: "No visible damage", passed: false, detail: "Possible stain detected" },
      ],
      notes:
        "Packaging looks unsafe to ship. Re-wrap the item and use a rigid container before retrying.",
      bonusMultiplier: 0.4,
      source: "mock",
    };
  }
  if (positive) {
    return {
      verdict: "pass",
      score: 0.93,
      checklist: [
        { label: "Item fully wrapped", passed: true },
        { label: "Corners and edges padded", passed: true },
        { label: "Original box or rigid container", passed: true },
        { label: "Box closed and taped", passed: true },
        { label: "Label area clear and dry", passed: true },
        { label: "No visible damage", passed: true },
      ],
      notes:
        "Looks ship-ready. Storage clock will start once the carrier scans the QR.",
      bonusMultiplier: 1.15,
      source: "mock",
    };
  }
  return {
    verdict: "needs_work",
    score: 0.68,
    checklist: [
      { label: "Item fully wrapped", passed: true },
      { label: "Corners and edges padded", passed: false, detail: "Add padding on corners" },
      { label: "Original box or rigid container", passed: true },
      { label: "Box closed and taped", passed: false, detail: "Tape both top and bottom seams" },
      { label: "Label area clear and dry", passed: true },
      { label: "No visible damage", passed: true },
    ],
    notes: "Almost there. Add corner padding and double-tape the seams, then resubmit.",
    bonusMultiplier: 0.85,
    source: "mock",
  };
}
