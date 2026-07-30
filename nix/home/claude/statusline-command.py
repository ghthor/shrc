#!/usr/bin/env python3
# Anthropic pricing is used unless Claude is configured for OpenRouter.

import json
import os
import subprocess
import sys
from pathlib import Path

os.environ["CLICOLOR_FORCE"] = "1"

# ---------------------------------------------------------------------------
# Default pricing: Anthropic / AWS Bedrock (per token)
# ---------------------------------------------------------------------------
ANTHROPIC_PRICES = {
    "input":       0.000003,
    "output":      0.000015,
    "cache_write": 0.000003750,
    "cache_read":  0.000000300,
}

# ---------------------------------------------------------------------------
# Color helpers (gum style)
# ---------------------------------------------------------------------------

def _gum(text: str, foreground: str) -> str:
    result = subprocess.run(
        ["gum", "style", f"--foreground={foreground}", text],
        capture_output=True, text=True,
    )
    return result.stdout.rstrip("\n") if result.returncode == 0 else text


def sep() -> str:
    return _gum(" | ", "#888888")


def color_model(text: str) -> str:
    return _gum(text, "#7697d6")


# Stylized glyph indicating which pricing/mode is active: a circled "O" when
# OpenRouter pricing was confirmed for this model, otherwise a circled "A" for
# the Anthropic / AWS Bedrock fallback pricing in effect above.
MODE_GLYPH_ANTHROPIC = "Ⓐ"
MODE_COLOR_ANTHROPIC = "#e8a87c"
MODE_GLYPH_OPENROUTER = "Ⓞ"
MODE_COLOR_OPENROUTER = "#7ec699"


def color_mode(text: str, confirmed_openrouter: bool) -> str:
    color = MODE_COLOR_OPENROUTER if confirmed_openrouter else MODE_COLOR_ANTHROPIC
    return _gum(text, color)


def color_ctx(text: str, pct: int) -> str:
    if pct >= 85:
        fg = "#cf6a4c"
    elif pct >= 60:
        fg = "#fad07a"
    else:
        fg = "#99ad6a"
    return _gum(text, fg)


def color_turn(text: str) -> str:
    return _gum(text, "#8fbfdc")


def color_session(text: str) -> str:
    return _gum(text, "#ffb964")


# ---------------------------------------------------------------------------
# OpenRouter pricing lookup
# ---------------------------------------------------------------------------

def fetch_or_pricing(model: str, auth_token: str, base_url: str) -> dict | None:
    """Return {field: float} prices for model, or None on failure."""
    cache_dir = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "claude-openrouter"
    cache_dir.mkdir(parents=True, exist_ok=True)

    result = subprocess.run(
        [
            "bkt", "--cache-dir", str(cache_dir),
            "--ttl", "24h", "--stale", "1h",
            "--scope", "claude-openrouter-pricing",
            "--",
            "curl", "--fail", "--silent", "--show-error",
            "-H", f"Authorization: Bearer {auth_token}",
            f"{base_url}/v1/models",
        ],
        capture_output=True, text=True,
    )
    if not result.stdout.strip():
        return None

    try:
        data = json.loads(result.stdout)
    except json.JSONDecodeError:
        return None

    for entry in data.get("data", []):
        if entry.get("id") == model:
            pricing = entry.get("pricing")
            if pricing is None:
                return {}  # model found but no pricing; still show OpenRouter glyph
            return {
                "input":       float(pricing.get("prompt", 0) or 0),
                "output":      float(pricing.get("completion", 0) or 0),
                "cache_write": float(pricing.get("input_cache_write", 0) or 0),
                "cache_read":  float(pricing.get("input_cache_read", 0) or 0),
            }
    return None  # model not found


# ---------------------------------------------------------------------------
# Session cost state
# ---------------------------------------------------------------------------

def _cost_file() -> Path:
    override = os.environ.get("CLAUDE_COST_FILE")
    if override:
        return Path(override)
    return Path(f"/tmp/claude-session-cost-{os.getppid()}")


def read_session_state(path: Path) -> tuple[float, str]:
    """Return (accumulated_cost, last_signature)."""
    try:
        raw = path.read_text().strip()
    except OSError:
        return 0.0, ""
    if "|" not in raw:
        return 0.0, ""
    cost_s, sig = raw.split("|", 1)
    try:
        return float(cost_s), sig
    except ValueError:
        return 0.0, ""


def write_session_state(path: Path, cost: float, signature: str) -> None:
    path.write_text(f"{cost:.10f}|{signature}\n")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    raw = sys.stdin.read()
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        data = {}

    model_obj = data.get("model") or {}
    model = model_obj.get("id") or model_obj.get("display_name") or "?"

    ctx_window = data.get("context_window") or {}
    used_pct = ctx_window.get("used_percentage")
    usage = ctx_window.get("current_usage") or {}
    input_tokens       = int(usage.get("input_tokens", 0) or 0)
    output_tokens      = int(usage.get("output_tokens", 0) or 0)
    cache_write_tokens = int(usage.get("cache_creation_input_tokens", 0) or 0)
    cache_read_tokens  = int(usage.get("cache_read_input_tokens", 0) or 0)

    prices = dict(ANTHROPIC_PRICES)
    openrouter_confirmed = False

    base_url = (os.environ.get("ANTHROPIC_BASE_URL") or "").rstrip("/")
    auth_token = os.environ.get("ANTHROPIC_AUTH_TOKEN") or ""

    if base_url == "https://openrouter.ai/api" and model != "?":
        or_prices = fetch_or_pricing(model, auth_token, base_url)
        if or_prices is not None:
            openrouter_confirmed = True
            if or_prices:  # non-empty means actual prices available
                prices.update(or_prices)

    turn_cost = (
        input_tokens       * prices["input"]
        + output_tokens    * prices["output"]
        + cache_write_tokens * prices["cache_write"]
        + cache_read_tokens  * prices["cache_read"]
    )

    cost_path = _cost_file()
    signature = f"{model}:{input_tokens}:{output_tokens}:{cache_write_tokens}:{cache_read_tokens}"
    prev_cost, last_sig = read_session_state(cost_path)

    if signature != last_sig:
        session_cost = prev_cost + turn_cost
        write_session_state(cost_path, session_cost, signature)
    else:
        session_cost = prev_cost

    mode_glyph = MODE_GLYPH_OPENROUTER if openrouter_confirmed else MODE_GLYPH_ANTHROPIC

    s = sep()
    model_s   = color_model(model) + " " + color_mode(mode_glyph, openrouter_confirmed)
    turn_s    = color_turn(f"~${turn_cost:.4f}")
    session_s = color_session(f"{session_cost:.4f}")

    parts = [model_s]
    if used_pct is not None:
        used_int = round(used_pct)
        parts.append(color_ctx(f"{used_int}%", used_int))
    parts.append(f"{turn_s}|{session_s}")

    print(s.join(parts))


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        sys.exit(0)
