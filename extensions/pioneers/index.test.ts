import {
  registerSingleProviderPlugin,
  resolveProviderPluginChoice,
} from "openclaw/plugin-sdk/plugin-test-runtime";
import { describe, expect, it } from "vitest";
import { runSingleProviderCatalog } from "../test-support/provider-model-test-helpers.js";
import pioneersPlugin from "./index.js";
import { applyPioneersConfig, PIONEERS_DEFAULT_MODEL_REF } from "./onboard.js";

describe("pioneers provider plugin", () => {
  it("registers Pioneers with api-key auth wizard metadata", async () => {
    const provider = await registerSingleProviderPlugin(pioneersPlugin);
    const resolved = resolveProviderPluginChoice({
      providers: [provider],
      choice: "pioneers-api-key",
    });

    expect(provider.id).toBe("pioneers");
    expect(provider.label).toBe("Pioneers");
    expect(provider.envVars).toEqual(["PIONEERS_API_KEY"]);
    expect(provider.auth).toHaveLength(1);
    expect(resolved).not.toBeNull();
    expect(resolved?.provider.id).toBe("pioneers");
    expect(resolved?.method.id).toBe("api-key");
  });

  it("builds the static Pioneers model catalog", async () => {
    const provider = await registerSingleProviderPlugin(pioneersPlugin);
    const catalogProvider = await runSingleProviderCatalog(provider);

    expect(catalogProvider.api).toBe("anthropic-messages");
    expect(catalogProvider.baseUrl).toBe("https://alpha.pioneers.dev");
    expect(catalogProvider.models?.map((model) => model.id)).toEqual(["auto"]);
    expect(catalogProvider.models?.[0]).toMatchObject({
      id: "auto",
      name: "Pioneer Auto",
      api: "anthropic-messages",
      contextWindow: 200_000,
      maxTokens: 16_384,
      input: ["text", "image"],
    });
  });

  it("owns the anthropic-by-model replay policy", async () => {
    const provider = await registerSingleProviderPlugin(pioneersPlugin);

    const policy = provider.buildReplayPolicy?.({
      modelApi: "anthropic-messages",
      modelId: "auto",
    } as never);

    expect(policy).toBeTruthy();
  });

  it("applies an Anthropic-messages provider config when the user pastes a key", () => {
    const next = applyPioneersConfig({});

    expect(next.agents?.defaults?.model).toMatchObject({
      primary: PIONEERS_DEFAULT_MODEL_REF,
    });
    expect(next.models?.providers?.pioneers).toMatchObject({
      api: "anthropic-messages",
      baseUrl: "https://alpha.pioneers.dev",
    });
    expect(next.models?.providers?.pioneers?.models?.[0]).toMatchObject({
      id: "auto",
      api: "anthropic-messages",
    });
  });

  it("publishes configured Pioneers models through plugin-owned catalog augmentation", async () => {
    const provider = await registerSingleProviderPlugin(pioneersPlugin);

    expect(
      provider.augmentModelCatalog?.({
        config: {
          models: {
            providers: {
              pioneers: {
                models: [
                  {
                    id: "auto",
                    name: "Pioneer Auto",
                    input: ["text", "image"],
                    contextWindow: 200_000,
                  },
                ],
              },
            },
          },
        },
      } as never),
    ).toEqual([
      {
        provider: "pioneers",
        id: "auto",
        name: "Pioneer Auto",
        input: ["text", "image"],
        contextWindow: 200_000,
      },
    ]);
  });
});
