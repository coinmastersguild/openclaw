import { readConfiguredProviderCatalogEntries } from "openclaw/plugin-sdk/provider-catalog-shared";
import { defineSingleProviderPluginEntry } from "openclaw/plugin-sdk/provider-entry";
import { buildProviderReplayFamilyHooks } from "openclaw/plugin-sdk/provider-model-shared";
import { applyPioneersConfig, PIONEERS_DEFAULT_MODEL_REF } from "./onboard.js";
import { buildPioneersProvider } from "./provider-catalog.js";

const PROVIDER_ID = "pioneers";

export default defineSingleProviderPluginEntry({
  id: PROVIDER_ID,
  name: "Pioneers Provider",
  description: "Bundled Pioneers (alpha.pioneers.dev) provider plugin",
  provider: {
    label: "Pioneers",
    docsPath: "/providers/pioneers",
    auth: [
      {
        methodId: "api-key",
        label: "Pioneers API key",
        hint: "API key",
        optionKey: "pioneersApiKey",
        flagName: "--pioneers-api-key",
        envVar: "PIONEERS_API_KEY",
        promptMessage: "Enter Pioneers API key",
        defaultModel: PIONEERS_DEFAULT_MODEL_REF,
        applyConfig: (cfg) => applyPioneersConfig(cfg),
        wizard: {
          choiceId: "pioneers-api-key",
          choiceLabel: "Pioneers API key",
          groupId: "pioneers",
          groupLabel: "Pioneers",
          groupHint: "API key",
        },
      },
    ],
    catalog: {
      buildProvider: buildPioneersProvider,
    },
    augmentModelCatalog: ({ config }) =>
      readConfiguredProviderCatalogEntries({
        config,
        providerId: PROVIDER_ID,
      }),
    matchesContextOverflowError: ({ errorMessage }) =>
      /\bpioneers\b.*(?:input.*too long|context.*exceed)/i.test(errorMessage),
    ...buildProviderReplayFamilyHooks({ family: "anthropic-by-model" }),
  },
});
