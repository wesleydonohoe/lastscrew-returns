// Baseten vision client for packaging QA.
//
// Hosts a vision model (e.g. Qwen2-VL, LLaVA-NeXT, or a fine-tuned packaging
// classifier) on Baseten. https://docs.baseten.co/overview
//
// We POST to the deployed model's /predict endpoint with a base64 image and a
// prompt. The model returns JSON we trust as the QA verdict.
//
// If BASETEN_API_KEY or BASETEN_MODEL_ID is missing, we fall back to a
// deterministic mock so the demo runs cold.

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
The user has kept an assembled furniture item and is now repackaging it as a micro-warehouse host.

Look at the photo and score whether the packaging is shippable. Score each item:
1. Item fully wrapped (blanket / shrink / original wrap)
2. Corners and edges padded
3. Original box OR comparable rigid container
4. Box closed and taped
5. Shipping label area clear and dry
6. No visible damage, stains, or wet spots

Return STRICT JSON only:
{
  "verdict": "pass" | "needs_work" | "fail",
  "score": <0..1>,
  "checklist": [{"label": "...", "passed": true|false, "detail": "..."}],
  "notes": "<one short paragraph>",
  "bonusMultiplier": <0..1.2>
}`;

export async function runPackagingQA(args: {
  imageBase64?: string;
  imageUrl?: string;
  photoDescription?: string;
  baseteenApiKey?: string;
  basetenModelId?: string;
}): Promise<PackagingQAResult> {
  const { imageBase64, imageUrl, photoDescription } = args;
  const apiKey = args.baseteenApiKey;
  const modelId = args.basetenModelId;

  if (!apiKey || !modelId) {
    return mockQA(photoDescription ?? "(no description)");
  }

  // Baseten model deployments expose POST https://model-<id>.api.baseten.co/production/predict
  // Different models accept different payloads — this targets vision LLMs that
  // follow an OpenAI-style chat completions schema.
  const url = `https://model-${modelId}.api.baseten.co/production/predict`;

  const messages: unknown[] = [
    {
      role: "user",
      content: [
        { type: "text", text: QA_PROMPT },
        ...(imageBase64
          ? [
              {
                type: "image_url",
                image_url: { url: `data:image/jpeg;base64,${imageBase64}` },
              },
            ]
          : []),
        ...(imageUrl ? [{ type: "image_url", image_url: { url: imageUrl } }] : []),
        ...(photoDescription
          ? [{ type: "text", text: `User-provided photo description: ${photoDescription}` }]
          : []),
      ],
    },
  ];

  const response = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Api-Key ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      messages,
      max_tokens: 600,
      temperature: 0.1,
    }),
  });

  if (!response.ok) {
    const body = await response.text().catch(() => "");
    throw new Error(`Baseten returned ${response.status}: ${body.slice(0, 200)}`);
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
  // Bias the verdict on whether the description sounds positive — keeps demo deterministic.
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
