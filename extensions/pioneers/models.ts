import { buildManifestModelProviderConfig } from "openclaw/plugin-sdk/provider-catalog-shared";
import type { ModelDefinitionConfig } from "openclaw/plugin-sdk/provider-model-shared";
import manifest from "./openclaw.plugin.json" with { type: "json" };

const PIONEERS_MANIFEST_PROVIDER = buildManifestModelProviderConfig({
  providerId: "pioneers",
  catalog: manifest.modelCatalog.providers.pioneers,
});

export const PIONEERS_BASE_URL = PIONEERS_MANIFEST_PROVIDER.baseUrl;

export const PIONEERS_MODEL_CATALOG: ModelDefinitionConfig[] = PIONEERS_MANIFEST_PROVIDER.models;

export function buildPioneersModelDefinition(
  model: (typeof PIONEERS_MODEL_CATALOG)[number],
): ModelDefinitionConfig {
  return {
    ...model,
    api: "anthropic-messages",
  };
}
