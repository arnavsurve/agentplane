import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Copy, Check } from "lucide-react";
import { Card, CardContent } from "./ui/card";
import type { Agent } from "../types/agent.types";
import { MODELS, getProviderDisplayName } from "../types/agent.types";

interface AgentCardProps {
  agent: Agent;
}

export function AgentCard({ agent }: AgentCardProps) {
  const [copied, setCopied] = useState(false);
  const navigate = useNavigate();

  // Get the model display name from the model value
  const getModelDisplayName = () => {
    const provider = agent.provider as keyof typeof MODELS;
    if (!MODELS[provider]) return agent.llm_model;

    const model = MODELS[provider].find((m) => m.value === agent.llm_model);
    return model ? model.label : agent.llm_model;
  };

  // Handle card click to navigate to agent detail
  const handleCardClick = () => {
    navigate(`/app/agents/${agent.id}`);
  };

  return (
    <Card
      className="overflow-hidden cursor-pointer transition-all duration-200 hover:shadow-md hover:border-primary/30 h-full"
      onClick={handleCardClick}
    >
      <CardContent className="p-4 flex flex-col h-full">
        {/* Agent Name */}
        <h3 className="text-xl font-semibold mb-3 truncate">{agent.name}</h3>

        {/* Model & Provider */}
        <div className="mb-4">
          <p className="text-xs text-muted-foreground uppercase tracking-wide mb-1">
            Model
          </p>
          <p className="text-sm font-medium">
            {getProviderDisplayName(agent.provider)} • {getModelDisplayName()}
          </p>
        </div>

        {/* Parameters Grid */}
        <div className="grid grid-cols-2 gap-3 mb-4">
          <div>
            <p className="text-xs text-muted-foreground uppercase tracking-wide mb-1">
              Temperature
            </p>
            <p className="text-sm font-medium">
              {agent.temperature !== undefined ? agent.temperature : "0.5"}
            </p>
          </div>
          <div>
            <p className="text-xs text-muted-foreground uppercase tracking-wide mb-1">
              Max Tokens
            </p>
            <p className="text-sm font-medium">
              {agent.max_tokens || "2048"}
            </p>
          </div>
        </div>

        {/* Agent ID with copy */}
        <div className="mt-auto">
          <p className="text-xs text-muted-foreground uppercase tracking-wide mb-1">
            Agent ID
          </p>
          <div
            className="flex items-center gap-2 p-2 bg-muted/50 rounded border border-border hover:bg-muted transition-colors group"
            onClick={(e) => {
              e.stopPropagation();
              navigator.clipboard.writeText(agent.id || "");
              setCopied(true);
              setTimeout(() => setCopied(false), 2000);
            }}
            title="Click to copy"
          >
            <code className="text-xs flex-1 truncate">{agent.id}</code>
            {copied ? (
              <Check className="w-3 h-3 text-green-500 flex-shrink-0" />
            ) : (
              <Copy className="w-3 h-3 opacity-50 group-hover:opacity-100 flex-shrink-0" />
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
