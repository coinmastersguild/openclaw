#!/usr/bin/env bash
set -euo pipefail

# CoinMastersGuild OpenClaw fork installer for macOS / Linux / WSL2.
# Adapted from the upstream `scripts/install.sh` flow but scoped to the
# `@coinmastersguild/openclaw` npm package and the
# `coinmastersguild/openclaw` GitHub repository.
#
# Usage:
#   curl -fsSL --proto '=https' --tlsv1.2 \
#     https://raw.githubusercontent.com/coinmastersguild/openclaw/main/scripts/install.fork.sh \
#     | bash
#
#   # …with options
#   curl -fsSL ... | bash -s -- --no-onboard
#   curl -fsSL ... | bash -s -- --install-method git
#   curl -fsSL ... | bash -s -- --version 2026.5.5
#
# Env equivalents:
#   OPENCLAW_FORK_INSTALL_METHOD=npm|git
#   OPENCLAW_FORK_VERSION=latest|<semver>|<git-ref>
#   OPENCLAW_FORK_GIT_DIR=<path>
#   OPENCLAW_FORK_NO_ONBOARD=1
#   OPENCLAW_FORK_DRY_RUN=1
#   OPENCLAW_FORK_VERBOSE=1

PACKAGE_NAME="@coinmastersguild/openclaw"
GIT_REPO_URL="https://github.com/coinmastersguild/openclaw.git"
NODE_MIN_MAJOR=22
NODE_RECOMMENDED_MAJOR=24

INSTALL_METHOD="${OPENCLAW_FORK_INSTALL_METHOD:-npm}"
PKG_VERSION="${OPENCLAW_FORK_VERSION:-latest}"
GIT_DIR="${OPENCLAW_FORK_GIT_DIR:-${HOME}/openclaw-cmg}"
NO_ONBOARD="${OPENCLAW_FORK_NO_ONBOARD:-0}"
DRY_RUN="${OPENCLAW_FORK_DRY_RUN:-0}"
VERBOSE="${OPENCLAW_FORK_VERBOSE:-0}"

BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GREEN=$'\033[32m'
YELLOW=$'\033[33m'; CYAN=$'\033[36m'; NC=$'\033[0m'

log()   { printf '%s[install.fork]%s %s\n' "$CYAN" "$NC" "$*"; }
warn()  { printf '%s[install.fork]%s %s\n' "$YELLOW" "$NC" "$*" >&2; }
error() { printf '%s[install.fork]%s %s\n' "$RED" "$NC" "$*" >&2; }
ok()    { printf '%s[install.fork]%s %s\n' "$GREEN" "$NC" "$*"; }

run() {
    if [[ "$VERBOSE" == "1" ]]; then
        printf '%s$ %s%s\n' "$DIM" "$*" "$NC" >&2
    fi
    if [[ "$DRY_RUN" == "1" ]]; then
        printf '%s[dry-run]%s %s\n' "$YELLOW" "$NC" "$*"
        return 0
    fi
    "$@"
}

usage() {
    cat <<USAGE
${BOLD}coinmastersguild/openclaw fork installer${NC}

Usage:
  curl -fsSL --proto '=https' --tlsv1.2 \\
    https://raw.githubusercontent.com/coinmastersguild/openclaw/main/scripts/install.fork.sh \\
    | bash [-s -- options]

Options:
  --install-method npm|git    Install via npm (default) or from a git checkout
  --npm                       Shortcut for --install-method npm
  --git                       Shortcut for --install-method git
  --version <spec>            npm version, dist-tag, or git ref (default: latest)
  --git-dir <path>            Git checkout directory (default: ~/openclaw-cmg)
  --no-onboard                Skip the post-install onboarding prompt
  --dry-run                   Print actions without applying changes
  --verbose                   Echo each command before running
  -h, --help                  Show this help

USAGE
}

while (( $# > 0 )); do
    case "$1" in
        --install-method|--method) INSTALL_METHOD="${2:-}"; shift 2 ;;
        --npm)       INSTALL_METHOD="npm"; shift ;;
        --git|--github) INSTALL_METHOD="git"; shift ;;
        --version)   PKG_VERSION="${2:-}"; shift 2 ;;
        --git-dir|--dir) GIT_DIR="${2:-}"; shift 2 ;;
        --no-onboard) NO_ONBOARD=1; shift ;;
        --onboard)    NO_ONBOARD=0; shift ;;
        --dry-run)   DRY_RUN=1; shift ;;
        --verbose)   VERBOSE=1; shift ;;
        -h|--help)   usage; exit 0 ;;
        *)           error "Unknown option: $1"; usage; exit 2 ;;
    esac
done

case "$INSTALL_METHOD" in
    npm|git) ;;
    *) error "--install-method must be 'npm' or 'git' (got '$INSTALL_METHOD')"; exit 2 ;;
esac

[[ "$VERBOSE" == "1" ]] && set -x || true

detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)  echo "linux" ;;
        *)      echo "unsupported" ;;
    esac
}

node_major() {
    if ! command -v node >/dev/null 2>&1; then echo 0; return; fi
    node -e 'process.stdout.write(String(process.versions.node.split(".")[0]))' 2>/dev/null || echo 0
}

ensure_node() {
    local current
    current="$(node_major)"
    if (( current >= NODE_MIN_MAJOR )); then
        ok "Node $(node -v) detected (>= ${NODE_MIN_MAJOR}.x required)"
        return 0
    fi
    log "Node ${NODE_MIN_MAJOR}+ not found; attempting install of Node ${NODE_RECOMMENDED_MAJOR}.x"
    case "$(detect_os)" in
        macos)
            if ! command -v brew >/dev/null 2>&1; then
                error "Homebrew not found. Install Homebrew (https://brew.sh) or Node ${NODE_MIN_MAJOR}+ manually, then re-run."
                exit 1
            fi
            run brew install "node@${NODE_RECOMMENDED_MAJOR}"
            run brew link --overwrite --force "node@${NODE_RECOMMENDED_MAJOR}" || true
            ;;
        linux)
            if command -v apt-get >/dev/null 2>&1; then
                run bash -c "curl -fsSL https://deb.nodesource.com/setup_${NODE_RECOMMENDED_MAJOR}.x | sudo -E bash -"
                run sudo apt-get install -y nodejs
            elif command -v dnf >/dev/null 2>&1; then
                run bash -c "curl -fsSL https://rpm.nodesource.com/setup_${NODE_RECOMMENDED_MAJOR}.x | sudo -E bash -"
                run sudo dnf install -y nodejs
            elif command -v yum >/dev/null 2>&1; then
                run bash -c "curl -fsSL https://rpm.nodesource.com/setup_${NODE_RECOMMENDED_MAJOR}.x | sudo -E bash -"
                run sudo yum install -y nodejs
            else
                error "No supported package manager. Install Node ${NODE_MIN_MAJOR}+ manually and re-run."
                exit 1
            fi
            ;;
        *)
            error "Unsupported OS. Use macOS, Linux, or WSL2."
            exit 1
            ;;
    esac
    current="$(node_major)"
    if (( current < NODE_MIN_MAJOR )); then
        error "Node install did not satisfy >= ${NODE_MIN_MAJOR}.x (still on $(node -v 2>/dev/null || echo 'none'))"
        exit 1
    fi
    ok "Node $(node -v) installed"
}

ensure_git() {
    if command -v git >/dev/null 2>&1; then return 0; fi
    log "git not found; installing"
    case "$(detect_os)" in
        macos) run brew install git ;;
        linux)
            if   command -v apt-get >/dev/null 2>&1; then run sudo apt-get install -y git
            elif command -v dnf     >/dev/null 2>&1; then run sudo dnf install -y git
            elif command -v yum     >/dev/null 2>&1; then run sudo yum install -y git
            else error "Install git manually and re-run."; exit 1
            fi
            ;;
    esac
}

existing_openclaw_bin() {
    type -P openclaw 2>/dev/null || true
}

resolve_existing_openclaw_owner() {
    # Returns "fork" if the existing global openclaw binary belongs to
    # @coinmastersguild/openclaw, "upstream" if it belongs to the bare
    # `openclaw` package, or "" if we can't tell.
    local bin
    bin="$(existing_openclaw_bin)"
    if [[ -z "$bin" ]]; then
        echo ""; return 0
    fi
    local target pkg_dir pkg_json owner=""
    target="$(readlink -f "$bin" 2>/dev/null || echo "$bin")"
    pkg_dir="${target}"
    while [[ -n "$pkg_dir" && "$pkg_dir" != "/" && ! -f "${pkg_dir}/package.json" ]]; do
        pkg_dir="$(dirname "$pkg_dir")"
    done
    pkg_json="${pkg_dir}/package.json"
    if [[ -f "$pkg_json" ]] && command -v node >/dev/null 2>&1; then
        owner="$(node -e "try{const p=require('$pkg_json');process.stdout.write(p.name||'')}catch(e){process.stdout.write('')}" 2>/dev/null || true)"
    fi
    echo "$owner"
}

install_via_npm() {
    local spec="${PACKAGE_NAME}@${PKG_VERSION}"
    local existing owner
    existing="$(existing_openclaw_bin)"
    if [[ -n "$existing" ]]; then
        owner="$(resolve_existing_openclaw_owner)"
        case "$owner" in
            "${PACKAGE_NAME}")
                log "Existing ${PACKAGE_NAME} install at ${existing}; upgrading"
                ;;
            "openclaw")
                if [[ "$DRY_RUN" == "1" ]]; then
                    warn "Detected an upstream 'openclaw' install at ${existing}."
                    warn "Real run would refuse to proceed: npm refuses to overwrite the shared 'openclaw' bin (EEXIST)."
                    warn "Workarounds: 'npm uninstall -g openclaw' or '--install-method git'."
                else
                    error "Detected an upstream 'openclaw' install at ${existing}."
                    error "The CoinMastersGuild fork shares the same 'openclaw' bin name and"
                    error "npm will refuse to overwrite it (EEXIST). Uninstall the upstream"
                    error "package first, then re-run this installer:"
                    error "    npm uninstall -g openclaw"
                    error "Or install side-by-side from a checkout: --install-method git"
                    exit 1
                fi
                ;;
            *)
                warn "Existing 'openclaw' binary at ${existing} (owner: ${owner:-unknown})."
                warn "If npm fails with EEXIST, run: npm uninstall -g openclaw"
                ;;
        esac
    fi
    log "Installing ${spec} globally via npm"
    run npm install -g "$spec"
}

install_via_git() {
    ensure_git
    log "Installing from git checkout at ${GIT_DIR}"
    if [[ -d "$GIT_DIR/.git" ]]; then
        run git -C "$GIT_DIR" fetch --tags --prune origin
    else
        run git clone "$GIT_REPO_URL" "$GIT_DIR"
    fi
    if [[ "$PKG_VERSION" != "latest" ]]; then
        run git -C "$GIT_DIR" checkout "$PKG_VERSION"
    else
        run git -C "$GIT_DIR" checkout main
        run git -C "$GIT_DIR" pull --ff-only origin main
    fi
    if ! command -v pnpm >/dev/null 2>&1; then
        log "pnpm not found; installing pnpm@10 globally"
        run npm install -g pnpm@10
    fi
    # Pass GIT_DIR as a positional argument so paths containing single quotes
    # or other shell metacharacters cannot alter the inner command.
    run bash -c 'cd "$1" && pnpm install' install-fork "$GIT_DIR"
    run bash -c 'cd "$1" && pnpm build' install-fork "$GIT_DIR"
    local bin_dir="${HOME}/.local/bin"
    run mkdir -p "$bin_dir"
    local wrapper="${bin_dir}/openclaw"
    if [[ "$DRY_RUN" != "1" ]]; then
        cat >"$wrapper" <<WRAPPER
#!/usr/bin/env bash
exec node "${GIT_DIR}/openclaw.mjs" "\$@"
WRAPPER
        chmod +x "$wrapper"
    fi
    ok "Wrote wrapper at ${wrapper}"
    case ":${PATH}:" in
        *":${bin_dir}:"*) ;;
        *) warn "${bin_dir} is not on your PATH. Add it to your shell profile to run 'openclaw' from anywhere." ;;
    esac
}

post_install() {
    if [[ "$NO_ONBOARD" == "1" ]]; then
        ok "Skipping onboarding (--no-onboard)"
        return 0
    fi
    if ! command -v openclaw >/dev/null 2>&1; then
        warn "'openclaw' is not on PATH yet. Open a new shell, then run 'openclaw onboard'."
        return 0
    fi
    if [[ "$DRY_RUN" == "1" ]]; then
        printf '%s[dry-run]%s openclaw onboard\n' "$YELLOW" "$NC"
        return 0
    fi
    # When piped from curl ... | bash, our own stdin is the script body, so
    # `[[ -t 0 ]]` is false. Reattach to /dev/tty (matching the upstream
    # installer's pattern) so the onboarding prompt can read the user's input.
    if [[ -r /dev/tty && -w /dev/tty ]]; then
        log "Running 'openclaw onboard' (re-run yourself if you Ctrl-C)"
        # Use exec in a subshell to swap stdin to the controlling terminal
        # without disturbing the parent shell's stdin.
        ( exec </dev/tty; openclaw onboard ) \
            || warn "Onboarding exited non-zero; you can re-run 'openclaw onboard' anytime."
        return 0
    fi
    warn "No controlling TTY available; skipping interactive onboarding. Run 'openclaw onboard' yourself."
}

main() {
    log "${BOLD}coinmastersguild/openclaw fork installer${NC}"
    log "method=${INSTALL_METHOD} version=${PKG_VERSION} package=${PACKAGE_NAME}"
    ensure_node
    case "$INSTALL_METHOD" in
        npm) install_via_npm ;;
        git) install_via_git ;;
    esac
    post_install
    ok "Done. Try: openclaw --help"
}

main "$@"
