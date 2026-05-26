import OpenAI from "openai";
import type { ChatCompletionMessageParam, ChatCompletionTool } from "openai/resources/chat/completions";

export const SUBCONSCIOUS_MODEL = "subconscious/tim-qwen3.6-27b";
export const SUBCONSCIOUS_BASE_URL = "https://api.subconscious.dev/v1";

export function createSubconsciousClient(apiKey: string): OpenAI {
  return new OpenAI({
    baseURL: SUBCONSCIOUS_BASE_URL,
    apiKey,
  });
}

export interface CompletionOptions {
  messages: ChatCompletionMessageParam[];
  tools?: ChatCompletionTool[];
  maxTokens?: number;
  temperature?: number;
  enableThinking?: boolean;
}

export interface CompletionResult {
  content: string;
  toolCalls?: OpenAI.Chat.Completions.ChatCompletionMessageToolCall[];
  finishReason: string | null;
  usage?: {
    promptTokens: number;
    completionTokens: number;
  };
}

export async function createCompletion(
  client: OpenAI,
  options: CompletionOptions,
): Promise<CompletionResult> {
  const response = await client.chat.completions.create({
    model: SUBCONSCIOUS_MODEL,
    messages: options.messages,
    tools: options.tools,
    max_tokens: options.maxTokens ?? 1000,
    temperature: options.temperature ?? 0.7,
    // @ts-expect-error Subconscious chat_template_kwargs extension
    chat_template_kwargs: { enable_thinking: options.enableThinking ?? false },
  });

  const choice = response.choices[0];
  return {
    content: choice.message.content ?? "",
    toolCalls: choice.message.tool_calls,
    finishReason: choice.finish_reason,
    usage: response.usage
      ? {
          promptTokens: response.usage.prompt_tokens,
          completionTokens: response.usage.completion_tokens,
        }
      : undefined,
  };
}
