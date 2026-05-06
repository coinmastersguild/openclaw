import {
  applyAgentDefaultModelPrimary,
  applyProviderConfigWithModelCatalog,
  type OpenClawConfig,
} from "openclaw/plugin-sdk/provider-onboard";
import { buildPioneersModelDefinition, PIONEERS_BASE_URL, PIONEERS_MODEL_CATALOG } from "./api.js";

export const PIONEERS_DEFAULT_MODEL_REF = "pioneers/auto";

function applyPioneersProviderConfig(cfg: OpenClawConfig): OpenClawConfig {
  const models = { ...cfg.agents?.defaults?.models };
  models[PIONEERS_DEFAULT_MODEL_REF] = {
    ...models[PIONEERS_DEFAULT_MODEL_REF],
    alias: models[PIONEERS_DEFAULT_MODEL_REF]?.alias ?? "Pioneers",
  };

  return applyProviderConfigWithModelCatalog(cfg, {
    agentModels: models,
    providerId: "pioneers",
    api: "anthropic-messages",
    baseUrl: PIONEERS_BASE_URL,
    catalogModels: PIONEERS_MODEL_CATALOG.map(buildPioneersModelDefinition),
  });
}

export function applyPioneersConfig(cfg: OpenClawConfig): OpenClawConfig {
  return applyAgentDefaultModelPrimary(
    applyPioneersProviderConfig(cfg),
    PIONEERS_DEFAULT_MODEL_REF,
  );
}
