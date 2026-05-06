import type { ModelProviderConfig } from "openclaw/plugin-sdk/provider-model-shared";
import {
  buildPioneersModelDefinition,
  PIONEERS_BASE_URL,
  PIONEERS_MODEL_CATALOG,
} from "./models.js";

export function buildPioneersProvider(): ModelProviderConfig {
  return {
    baseUrl: PIONEERS_BASE_URL,
    api: "anthropic-messages",
    models: PIONEERS_MODEL_CATALOG.map(buildPioneersModelDefinition),
  };
}
