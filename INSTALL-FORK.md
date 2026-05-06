# Installing the CoinMastersGuild OpenClaw Fork

This is the install path for the **CoinMastersGuild fork** of OpenClaw, published on npm as `@coinmastersguild/openclaw`. The CLI binary is still `openclaw` so existing docs, scripts, and muscle memory keep working.

## Install (one-liner)

```bash
curl -fsSL --proto '=https' --tlsv1.2 \
  https://raw.githubusercontent.com/coinmastersguild/openclaw/main/scripts/install.fork.sh \
  | bash
```

This downloads `scripts/install.fork.sh`, ensures Node 22+, installs `@coinmastersguild/openclaw@latest` globally via npm, and runs `openclaw onboard`. Onboarding reattaches to your terminal via `/dev/tty`, so it works correctly even though stdin is the curl pipe.

> **Existing upstream install?** Both packages ship the same `openclaw` binary, so npm refuses to overwrite. The installer detects this and asks you to remove the upstream package first:
>
> ```bash
> npm uninstall -g openclaw
> ```
>
> Then re-run the curl one-liner. Or use `--install-method git` to install side-by-side from a checkout.

### Common variations

```bash
# Skip onboarding
... | bash -s -- --no-onboard

# Pin a specific published version
... | bash -s -- --version 2026.5.5-cmg.1

# Build from a local git checkout instead of npm
... | bash -s -- --install-method git

# Print actions without applying them
... | bash -s -- --dry-run --verbose
```

Full flags: `... | bash -s -- --help`.

## Operator setup (one-time)

Before tag pushes can publish to npm, the fork repo needs:

1. **npm scope ownership.** Create the `@coinmastersguild` org on npmjs.com (or use an existing one your account owns).
2. **`NPM_TOKEN` repo secret.** On npmjs.com create an Automation token with publish access to the scope, then add it as `NPM_TOKEN` under `Settings → Secrets and variables → Actions` for `coinmastersguild/openclaw`.
3. **(Optional) reserve the package.** A first manual `npm publish` of an empty stub from a local clone reserves the name; the workflow can take over after that. Or just let the first tag push do it.

## Cutting a release

```bash
# Pick a fork-suffixed version. The pattern v*-cmg.* triggers the workflow.
git tag v2026.5.5-cmg.1
git push origin v2026.5.5-cmg.1
```

The `release-fork` workflow (`.github/workflows/release-fork.yml`):

1. Installs deps and runs `pnpm build` with the in-tree package name (`openclaw`) so workspace imports like `from "openclaw/plugin-sdk/*"` resolve.
2. Rewrites `package.json` `name` → `@coinmastersguild/openclaw` and `version` → the tag value (without the leading `v`).
3. Runs `npm publish --access public`.

You can also dispatch manually from the Actions tab with an explicit version and an optional dry-run.

## Why we don't rename `name` in-tree

The in-tree `package.json` keeps `"name": "openclaw"` on purpose. Renaming it would break ~50+ test fixtures, RTT harnesses, and CI assertions (e.g. `test/scripts/install-sh.test.ts`, `test/scripts/rtt-harness.test.ts`) that hard-code `openclaw@latest`/`openclaw@beta`. Doing the rename at publish-time only:

- keeps upstream merges clean (no churn in shared test fixtures),
- still publishes the fork under a unique scoped name,
- leaves the CLI binary name as `openclaw` (set via `bin`, independent of npm package name).

## Uninstalling

```bash
npm uninstall -g @coinmastersguild/openclaw
```

If you also installed the upstream `openclaw` package, uninstall that separately:

```bash
npm uninstall -g openclaw
```
