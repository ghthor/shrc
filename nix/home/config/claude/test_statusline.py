#!/usr/bin/env python3
"""Regression suite for the Claude statusline command.

Runs the target script (Bash or Python) as a subprocess, pipes JSON fixtures
through it, strips ANSI escape sequences via ansi2txt, and asserts plain-text
output.

Usage:
  python3 test_statusline.py                   # tests statusline-command.sh
  TARGET=statusline-command.py python3 test_statusline.py
"""

import json
import os
import stat
import subprocess
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

HERE = Path(__file__).parent.resolve()
TARGET = os.environ.get("TARGET", "statusline-command.sh")
SCRIPT = HERE / TARGET


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

BASIC_FIXTURE = {
    "model": {"id": "anthropic/claude-sonnet-4-5"},
    "context_window": {
        "used_percentage": 25.0,
        "current_usage": {
            "input_tokens": 5000,
            "output_tokens": 200,
            "cache_creation_input_tokens": 0,
            "cache_read_input_tokens": 0,
        },
    },
}

NO_CTX_FIXTURE = {
    "model": {"id": "anthropic/claude-sonnet-4-5"},
}

CTX_60_FIXTURE = {
    "model": {"id": "anthropic/claude-sonnet-4-5"},
    "context_window": {
        "used_percentage": 60.0,
        "current_usage": {
            "input_tokens": 1000,
            "output_tokens": 100,
            "cache_creation_input_tokens": 0,
            "cache_read_input_tokens": 0,
        },
    },
}

CTX_85_FIXTURE = {
    "model": {"id": "anthropic/claude-sonnet-4-5"},
    "context_window": {
        "used_percentage": 85.0,
        "current_usage": {
            "input_tokens": 1000,
            "output_tokens": 100,
            "cache_creation_input_tokens": 0,
            "cache_read_input_tokens": 0,
        },
    },
}

DISPLAY_NAME_FIXTURE = {
    "model": {"display_name": "Claude Sonnet"},
    "context_window": {
        "used_percentage": 10.0,
        "current_usage": {
            "input_tokens": 500,
            "output_tokens": 50,
            "cache_creation_input_tokens": 0,
            "cache_read_input_tokens": 0,
        },
    },
}

NO_MODEL_FIXTURE = {
    "context_window": {
        "used_percentage": 10.0,
        "current_usage": {
            "input_tokens": 500,
            "output_tokens": 50,
            "cache_creation_input_tokens": 0,
            "cache_read_input_tokens": 0,
        },
    },
}

OR_FIXTURE = {
    "model": {"id": "openai/gpt-5.6-luna"},
    "context_window": {
        "used_percentage": 12.0,
        "current_usage": {
            "input_tokens": 10000,
            "output_tokens": 500,
            "cache_creation_input_tokens": 100,
            "cache_read_input_tokens": 200,
        },
    },
}

OR_FIXTURE_2 = {
    "model": {"id": "openai/gpt-5.6-luna"},
    "context_window": {
        "used_percentage": 20.0,
        "current_usage": {
            "input_tokens": 20000,
            "output_tokens": 1000,
            "cache_creation_input_tokens": 200,
            "cache_read_input_tokens": 400,
        },
    },
}

# A pricing response with known per-token prices for openai/gpt-5.6-luna
# prompt=0.0000005, completion=0.000003 — very different from Anthropic fallback
OR_PRICING_RESPONSE = {
    "data": [
        {
            "id": "openai/gpt-5.6-luna",
            "pricing": {
                "prompt": "0.0000005",
                "completion": "0.000003",
                "input_cache_write": "0.000000625",
                "input_cache_read": "0.00000005",
            },
        }
    ]
}

# A pricing response where the model is listed but has no pricing block
OR_NO_PRICING_RESPONSE = {
    "data": [
        {
            "id": "openai/gpt-5.6-luna",
        }
    ]
}

# A pricing response that doesn't include our model at all
OR_UNKNOWN_MODEL_RESPONSE = {
    "data": [
        {
            "id": "some/other-model",
            "pricing": {"prompt": "0.000001", "completion": "0.000005"},
        }
    ]
}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def strip_ansi(text: str) -> str:
    """Strip ANSI escape sequences via ansi2txt."""
    result = subprocess.run(
        ["ansi2txt"],
        input=text,
        capture_output=True,
        text=True,
    )
    return result.stdout


def make_fake_bin(tmpdir: Path, name: str, body: str) -> None:
    """Write an executable script to tmpdir/name."""
    path = tmpdir / name
    path.write_text("#!/usr/bin/env bash\n" + textwrap.dedent(body))
    path.chmod(path.stat().st_mode | stat.S_IEXEC)


def make_fake_gum(tmpdir: Path) -> None:
    """Fake gum: emit its last positional argument verbatim (ignores --foreground etc.)."""
    make_fake_bin(tmpdir, "gum", """\
        # Collect only positional args (skip flag pairs and flag=value args)
        args=()
        skip=0
        for arg in "$@"; do
          if [[ $skip -eq 1 ]]; then skip=0; continue; fi
          if [[ "$arg" == --*=* ]]; then continue; fi
          if [[ "$arg" == --* ]]; then skip=1; continue; fi
          args+=("$arg")
        done
        # For "gum style ... TEXT", the last positional arg is the text
        printf '%s' "${args[-1]}"
    """)


def make_fake_bkt(tmpdir: Path, pricing_json: dict | None) -> None:
    """Fake bkt: ignore all bkt flags and emit pricing_json (or nothing on None)."""
    if pricing_json is None:
        body = "exit 0\n"
    else:
        escaped = json.dumps(json.dumps(pricing_json))  # shell-safe
        body = f"printf '%s' {escaped}\n"
    make_fake_bin(tmpdir, "bkt", body)


def run_statusline(
    fixture: dict,
    *,
    env_extra: dict | None = None,
    fake_bin_dir: Path | None = None,
    cost_file: str | None = None,
) -> str:
    """Run the target statusline script and return ANSI-stripped stdout."""
    env = {
        "HOME": os.environ["HOME"],
        "PATH": os.environ["PATH"],
        "CLICOLOR_FORCE": "1",
    }
    if fake_bin_dir:
        env["PATH"] = f"{fake_bin_dir}:{env['PATH']}"
    if cost_file:
        env["CLAUDE_COST_FILE"] = cost_file
    if env_extra:
        env.update(env_extra)

    cmd = ["bash", str(SCRIPT)] if str(SCRIPT).endswith(".sh") else ["python3", str(SCRIPT)]
    proc = subprocess.run(
        cmd,
        input=json.dumps(fixture),
        capture_output=True,
        text=True,
        env=env,
    )
    return strip_ansi(proc.stdout)


def extract_cost(text: str, label: str) -> float:
    """Pull the numeric value from the combined '~$0.0004|0.0021' turn|session segment."""
    import re
    m = re.search(r'~\$([0-9]+\.[0-9]+)\|([0-9]+\.[0-9]+)', text)
    if not m:
        raise AssertionError(f"Could not find ~$.../... in: {repr(text)}")
    if label == "turn":
        return float(m.group(1))
    if label == "session":
        return float(m.group(2))
    raise ValueError(f"unknown label {label!r}")


# ---------------------------------------------------------------------------
# Non-OpenRouter tests
# ---------------------------------------------------------------------------

class TestNonOpenRouter(unittest.TestCase):
    def setUp(self):
        self._tmpdir = tempfile.TemporaryDirectory()
        self.tmpdir = Path(self._tmpdir.name)
        make_fake_gum(self.tmpdir)
        self._cost = self.tmpdir / "cost"

    def tearDown(self):
        self._tmpdir.cleanup()

    def _run(self, fixture):
        return run_statusline(fixture, fake_bin_dir=self.tmpdir, cost_file=str(self._cost))

    def test_basic_model_and_ctx(self):
        out = self._run(BASIC_FIXTURE)
        self.assertIn("anthropic/claude-sonnet-4-5", out)
        self.assertIn("25%", out)
        self.assertRegex(out, r'~\$[0-9]+\.[0-9]+\|[0-9]+\.[0-9]+')

    def test_no_context_window(self):
        out = self._run(NO_CTX_FIXTURE)
        self.assertIn("anthropic/claude-sonnet-4-5", out)
        self.assertNotIn("%", out)
        self.assertRegex(out, r'~\$[0-9]+\.[0-9]+\|[0-9]+\.[0-9]+')

    def test_ctx_60_percent(self):
        out = self._run(CTX_60_FIXTURE)
        self.assertIn("60%", out)

    def test_ctx_85_percent(self):
        out = self._run(CTX_85_FIXTURE)
        self.assertIn("85%", out)

    def test_display_name_fallback(self):
        out = self._run(DISPLAY_NAME_FIXTURE)
        self.assertIn("Claude Sonnet", out)

    def test_unknown_model_shows_question_mark(self):
        out = self._run(NO_MODEL_FIXTURE)
        self.assertIn("?", out)

    def test_bedrock_glyph_without_openrouter(self):
        out = self._run(BASIC_FIXTURE)
        self.assertIn("Ⓐ", out)
        self.assertNotIn("Ⓞ", out)

    def test_session_accumulates_across_turns(self):
        out1 = run_statusline(BASIC_FIXTURE, fake_bin_dir=self.tmpdir, cost_file=str(self._cost))
        out2 = run_statusline(CTX_60_FIXTURE, fake_bin_dir=self.tmpdir, cost_file=str(self._cost))
        cost1 = extract_cost(out1, "session")
        cost2 = extract_cost(out2, "session")
        self.assertGreater(cost2, cost1, "session cost should grow after a new turn")

    def test_session_idempotent_on_same_turn(self):
        out1 = run_statusline(BASIC_FIXTURE, fake_bin_dir=self.tmpdir, cost_file=str(self._cost))
        out2 = run_statusline(BASIC_FIXTURE, fake_bin_dir=self.tmpdir, cost_file=str(self._cost))
        cost1 = extract_cost(out1, "session")
        cost2 = extract_cost(out2, "session")
        self.assertAlmostEqual(cost1, cost2, places=6,
                               msg="repeated identical turn should not increase session cost")


# ---------------------------------------------------------------------------
# OpenRouter tests
# ---------------------------------------------------------------------------

OR_ENV = {
    "ANTHROPIC_BASE_URL": "https://openrouter.ai/api",
    "ANTHROPIC_AUTH_TOKEN": "fake-token-for-tests",
}

OR_ENV_SLASH = {
    "ANTHROPIC_BASE_URL": "https://openrouter.ai/api/",
    "ANTHROPIC_AUTH_TOKEN": "fake-token-for-tests",
}


class TestOpenRouter(unittest.TestCase):
    def setUp(self):
        self._tmpdir = tempfile.TemporaryDirectory()
        self.tmpdir = Path(self._tmpdir.name)
        make_fake_gum(self.tmpdir)
        self._cost = self.tmpdir / "cost"

    def tearDown(self):
        self._tmpdir.cleanup()

    def _run(self, fixture, pricing_json, env=None):
        make_fake_bkt(self.tmpdir, pricing_json)
        return run_statusline(
            fixture,
            fake_bin_dir=self.tmpdir,
            cost_file=str(self._cost),
            env_extra={**(env or OR_ENV)},
        )

    def test_known_model_with_pricing_shows_openrouter_glyph(self):
        out = self._run(OR_FIXTURE, OR_PRICING_RESPONSE)
        self.assertIn("Ⓞ", out)
        self.assertIn("openai/gpt-5.6-luna", out)

    def test_known_model_with_pricing_uses_or_prices(self):
        # Anthropic fallback: input=0.000003, output=0.000015
        # OR prices: input=0.0000005, output=0.000003 — ~6x cheaper
        out_or = self._run(OR_FIXTURE, OR_PRICING_RESPONSE)
        cost_or = extract_cost(out_or, "turn")

        make_fake_bkt(self.tmpdir, None)  # no pricing — fall back to Anthropic
        out_fb = run_statusline(
            OR_FIXTURE,
            fake_bin_dir=self.tmpdir,
            cost_file=str(self.tmpdir / "cost2"),
            env_extra=OR_ENV,
        )
        cost_fb = extract_cost(out_fb, "turn")
        self.assertLess(cost_or, cost_fb,
                        "OR prices are much lower than Anthropic fallback for luna")

    def test_known_model_no_pricing_shows_openrouter_glyph(self):
        out = self._run(OR_FIXTURE, OR_NO_PRICING_RESPONSE)
        self.assertIn("Ⓞ", out)

    def test_unknown_model_shows_bedrock_glyph(self):
        out = self._run(OR_FIXTURE, OR_UNKNOWN_MODEL_RESPONSE)
        self.assertNotIn("Ⓞ", out)
        self.assertIn("Ⓐ", out)

    def test_empty_pricing_response_shows_bedrock_glyph(self):
        out = self._run(OR_FIXTURE, None)
        self.assertNotIn("Ⓞ", out)
        self.assertIn("Ⓐ", out)

    def test_trailing_slash_base_url_still_detects_or(self):
        out = self._run(OR_FIXTURE, OR_PRICING_RESPONSE, env=OR_ENV_SLASH)
        self.assertIn("Ⓞ", out)

    def test_session_idempotent_on_same_turn(self):
        make_fake_bkt(self.tmpdir, OR_PRICING_RESPONSE)
        out1 = run_statusline(OR_FIXTURE, fake_bin_dir=self.tmpdir,
                              cost_file=str(self._cost), env_extra=OR_ENV)
        out2 = run_statusline(OR_FIXTURE, fake_bin_dir=self.tmpdir,
                              cost_file=str(self._cost), env_extra=OR_ENV)
        self.assertAlmostEqual(
            extract_cost(out1, "session"),
            extract_cost(out2, "session"),
            places=6,
        )

    def test_session_accumulates_across_turns(self):
        make_fake_bkt(self.tmpdir, OR_PRICING_RESPONSE)
        out1 = run_statusline(OR_FIXTURE, fake_bin_dir=self.tmpdir,
                              cost_file=str(self._cost), env_extra=OR_ENV)
        out2 = run_statusline(OR_FIXTURE_2, fake_bin_dir=self.tmpdir,
                              cost_file=str(self._cost), env_extra=OR_ENV)
        self.assertGreater(
            extract_cost(out2, "session"),
            extract_cost(out1, "session"),
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
