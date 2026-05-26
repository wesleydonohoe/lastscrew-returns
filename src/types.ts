export interface AgentConfig {
  name: string;
  systemPrompt: string;
  instructions: string;
  enableThinking: boolean;
  maxTokens: number;
  temperature: number;
  enabledTools: string[];
  cronInstructions: string;
}

export interface AgentRunRecord {
  id: string;
  trigger: "cron" | "api" | "button" | "webhook";
  status: "running" | "completed" | "failed";
  input: string;
  output?: string;
  error?: string;
  usage?: {
    promptTokens: number;
    completionTokens: number;
  };
  createdAt: string;
  completedAt?: string;
}

export interface Env {
  SUBCONSCIOUS_API_KEY: string;
  BASETEN_API_KEY?: string;
  BASETEN_MODEL_ID?: string;
  BASETEN_MODEL_NAME?: string;
  /** "predict" (Python Truss) | "openai" (trt_llm config-only). Default predict. */
  BASETEN_ENDPOINT?: string;
  WEBHOOK_SECRET?: string;
  AGENT_KV: KVNamespace;
  ASSETS: Fetcher;
}

export const CONFIG_KEY = "agent:config";
export const RUNS_PREFIX = "agent:run:";

export const DEFAULT_AGENT_CONFIG: AgentConfig = {
  name: "LastScrew Pricing",
  systemPrompt:
    "You are LastScrew Pricing — a careful pricing agent for Wayfair's micro-warehouse host program. Always use tools to gather facts before deciding numbers.",
  instructions:
    "Compute a host offer for order WF-ORDER-8821 in ZIP 02116. Follow the get_item_details → get_local_demand → get_warehouse_pressure flow and return strict JSON.",
  enableThinking: false,
  maxTokens: 900,
  temperature: 0.4,
  enabledTools: [
    "get_item_details",
    "get_local_demand",
    "get_warehouse_pressure",
    "log_packaging_check",
  ],
  cronInstructions:
    "Daily check: estimate how many active hosts are in our network and flag any items past max_storage_days.",
};
