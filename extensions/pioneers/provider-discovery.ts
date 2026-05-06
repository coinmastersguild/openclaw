import type { ProviderPlugin } from "openclaw/plugin-sdk/provider-model-shared";
import { buildPioneersProvider } from "./provider-catalog.js";

const pioneersProviderDiscovery: ProviderPlugin = {
  id: "pioneers",
  label: "Pioneers",
  docsPath: "/providers/pioneers",
  auth: [],
  staticCatalog: {
    order: "simple",
    run: async () => ({
      provider: buildPioneersProvider(),
    }),
  },
};

export default pioneersProviderDiscovery;
