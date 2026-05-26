import type { ToolDefinition } from "./tools";

export function buildSystemPrompt(
  persona: string,
  tools: ToolDefinition[],
): string {
  const toolDocs =
    tools.length > 0
      ? tools
          .map((tool) => {
            const schema = JSON.stringify(tool.parameters);
            return `- ${tool.name}: ${tool.description}\n  input schema: ${schema}`;
          })
          .join("\n")
      : "No tools are enabled. Answer from your own knowledge.";

  return `${persona}

# How you must respond
Every message you send is a SINGLE JSON object — no prose outside the JSON.
Each turn, choose exactly ONE action:

1. Call a tool:
   { "action": "tool_call", "tool": "<tool_name>", "arguments": { ... } }

2. Give your final answer:
   { "action": "final_answer", "content": "<your answer>" }

Rules:
- Use the EXACT tool name from the list below.
- "arguments" must satisfy that tool's input schema.
- Call ONE tool at a time. You'll see each tool's result before your next turn.
- Stop with a final_answer as soon as you can.

# Available tools
${toolDocs}`;
}
