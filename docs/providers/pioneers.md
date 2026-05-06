---
summary: "Pioneers setup (auth + model selection)"
title: "Pioneers"
read_when:
  - You want to use Pioneers (alpha.pioneers.dev) with OpenClaw
  - You need the API key env var or CLI auth choice
---

[Pioneers](https://alpha.pioneers.dev) is an Anthropic-compatible smart router. It exposes Anthropic's `/v1/messages` surface and routes the single user-facing model `auto` to a best-fit backend internally.

| Property | Value                         |
| -------- | ----------------------------- |
| Provider | `pioneers`                    |
| Auth     | `PIONEERS_API_KEY`            |
| API      | Anthropic Messages compatible |
| Base URL | `https://alpha.pioneers.dev`  |

## Getting started

<Steps>
  <Step title="Get your API key">
    Create an API key at [alpha.pioneers.dev/keys](https://alpha.pioneers.dev/keys). Pioneers keys are prefixed `sk-pioneer-`.
  </Step>
  <Step title="Run onboarding">
    ```bash
    openclaw onboard --auth-choice pioneers-api-key
    ```

    This will prompt for your API key and set `pioneers/auto` as the default model.

  </Step>
  <Step title="Verify models are available">
    ```bash
    openclaw models list --provider pioneers
    ```

    To inspect the bundled static catalog without requiring a running Gateway,
    use:

    ```bash
    openclaw models list --all --provider pioneers
    ```

  </Step>
</Steps>

<AccordionGroup>
  <Accordion title="Non-interactive setup">
    For scripted or headless installations, pass all flags directly:

    ```bash
    openclaw onboard --non-interactive \
      --mode local \
      --auth-choice pioneers-api-key \
      --pioneers-api-key "$PIONEERS_API_KEY" \
      --skip-health \
      --accept-risk
    ```

  </Accordion>
</AccordionGroup>

<Warning>
If the Gateway runs as a daemon (launchd/systemd), make sure `PIONEERS_API_KEY`
is available to that process (for example, in `~/.openclaw/.env` or via
`env.shellEnv`).
</Warning>

## Built-in catalog

| Model ref       | Name         | Input        | Context | Max output | Notes                                    |
| --------------- | ------------ | ------------ | ------- | ---------- | ---------------------------------------- |
| `pioneers/auto` | Pioneer Auto | text + image | 200,000 | 16,384     | Routes to a best-fit backend server-side |

<Tip>
Pioneers exposes one user-facing model. Underlying backends are selected by the
service. To inspect the live backend list use:

```bash
curl -H "x-api-key: $PIONEERS_API_KEY" https://alpha.pioneers.dev/api/v1/chat/models
```

</Tip>

## Config example

```json5
{
  env: { PIONEERS_API_KEY: "sk-pioneer-..." },
  agents: {
    defaults: {
      model: { primary: "pioneers/auto" },
    },
  },
}
```

## Related

<CardGroup cols={2}>
  <Card title="Model selection" href="/concepts/model-providers" icon="layers">
    Choosing providers, model refs, and failover behavior.
  </Card>
  <Card title="Configuration reference" href="/gateway/configuration-reference" icon="gear">
    Full config reference for agents, models, and providers.
  </Card>
</CardGroup>
