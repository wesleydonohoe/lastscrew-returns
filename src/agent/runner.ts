import type { ChatCompletionMessageParam } from "openai/resources/chat/completions";
import { createSubconsciousClient, createCompletion } from "../subconscious/client";
import type { AgentConfig } from "../types";
import { executeTool, getOpenAITools } from "./tools";

export interface RunAgentInput {
  config: AgentConfig;
  instructions: string;
  apiKey: string;
  maxToolRounds?: number;
}

export interface RunAgentResult {
  answer: string;
  toolCalls: Array<{ name: string; arguments: string; result: string }>;
  usage?: {
    promptTokens: number;
    completionTokens: number;
  };
}

const MAX_TOOL_ROUNDS = 5;

export async function runAgent(input: RunAgentInput): Promise<RunAgentResult> {
  const client = createSubconsciousClient(input.apiKey);
  const tools = getOpenAITools(input.config.enabledTools);
  const messages: ChatCompletionMessageParam[] = [
    { role: "system", content: input.config.systemPrompt },
    { role: "user", content: input.instructions },
  ];

  const toolCalls: RunAgentResult["toolCalls"] = [];
  let totalUsage = { promptTokens: 0, completionTokens: 0 };
  const maxRounds = input.maxToolRounds ?? MAX_TOOL_ROUNDS;

  for (let round = 0; round < maxRounds; round++) {
    const result = await createCompletion(client, {
      messages,
      tools: tools.length > 0 ? tools : undefined,
      maxTokens: input.config.maxTokens,
      temperature: input.config.temperature,
      enableThinking: input.config.enableThinking,
    });

    if (result.usage) {
      totalUsage.promptTokens += result.usage.promptTokens;
      totalUsage.completionTokens += result.usage.completionTokens;
    }

    if (!result.toolCalls?.length) {
      return {
        answer: result.content,
        toolCalls,
        usage: totalUsage,
      };
    }

    messages.push({
      role: "assistant",
      content: result.content,
      tool_calls: result.toolCalls.map((tc) => ({
        id: tc.id,
        type: "function" as const,
        function: {
          name: tc.function.name,
          arguments: tc.function.arguments,
        },
      })),
    });

    for (const tc of result.toolCalls) {
      const toolResult = await executeTool(tc.function.name, tc.function.arguments);
      toolCalls.push({
        name: tc.function.name,
        arguments: tc.function.arguments,
        result: toolResult,
      });
      messages.push({
        role: "tool",
        tool_call_id: tc.id,
        content: toolResult,
      });
    }
  }

  return {
    answer: "Agent reached maximum tool rounds without a final answer.",
    toolCalls,
    usage: totalUsage,
  };
}
