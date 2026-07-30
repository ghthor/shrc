#!/usr/bin/env bash
# Anthropic pricing is used unless Claude is configured for OpenRouter.

export CLICOLOR_FORCE=1

input=$(cat)
model=$(jq -r '.model.id // .model.display_name // "?"' <<<"$input")
used=$(jq -r '.context_window.used_percentage // empty' <<<"$input")

input_tokens=$(jq -r '.context_window.current_usage.input_tokens // 0' <<<"$input")
output_tokens=$(jq -r '.context_window.current_usage.output_tokens // 0' <<<"$input")
cache_write_tokens=$(jq -r '.context_window.current_usage.cache_creation_input_tokens // 0' <<<"$input")
cache_read_tokens=$(jq -r '.context_window.current_usage.cache_read_input_tokens // 0' <<<"$input")

# Anthropic / AWS Bedrock pricing (per 1M tokens), used as a safe fallback.
input_price=0.000003
output_price=0.000015
cache_write_price=0.000003750
cache_read_price=0.000000300

# OpenRouter exposes current per-token pricing through its model API. Keep the
# response in a persistent per-user cache so statusline refreshes do not make a
# network request on every redraw and reboots do not discard the pricing data.
openrouter_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-openrouter"
openrouter_status=""
mkdir -p "$openrouter_cache_dir"

if [[ "${ANTHROPIC_BASE_URL%/}" == "https://openrouter.ai/api" && "$model" != "?" ]]; then
  pricing_json=$(bkt --cache-dir "$openrouter_cache_dir" \
    --ttl 24h --stale 1h --scope claude-openrouter-pricing \
    -- curl --fail --silent --show-error \
      -H "Authorization: Bearer ${ANTHROPIC_AUTH_TOKEN}" \
      "https://openrouter.ai/api/v1/models" 2>/dev/null || true)

  # bkt can return a stale response while refreshing it asynchronously. If the
  # cache is unavailable, leave the Anthropic fallback prices untouched.
  if [[ -z "$pricing_json" ]]; then
    pricing_json=''
  fi

  if [[ -n "$pricing_json" ]]; then
    read -r input_price output_price cache_write_price cache_read_price < <(
      jq -r --arg model "$model" '
        .data[] | select(.id == $model) | .pricing // empty |
        [(.prompt // ""), (.completion // ""), (.input_cache_write // "0"), (.input_cache_read // "0")] |
        @tsv
      ' <<<"$pricing_json" 2>/dev/null
    )

    if [[ -n "$input_price" && -n "$output_price" ]]; then
      openrouter_status="1"
    fi
  fi

  # The models endpoint is successful even if this model has no pricing data.
  if [[ -z "$openrouter_status" ]] && jq -e --arg model "$model" '.data[] | select(.id == $model)' >/dev/null 2>&1 <<<"$pricing_json"; then
    openrouter_status="1"
  fi
fi

# Stylized glyph indicating which pricing/mode is active: a circled "O" when
# OpenRouter pricing was confirmed for this model, otherwise a circled "A" for
# the Anthropic / AWS Bedrock fallback pricing in effect above.
mode_glyph="Ⓐ"
mode_color="#e8a87c"
if [[ -n "$openrouter_status" ]]; then
  mode_glyph="Ⓞ"
  mode_color="#7ec699"
fi

turn_cost=$(awk -v input="$input_tokens" \
  -v output="$output_tokens" \
  -v cache_write="$cache_write_tokens" \
  -v cache_read="$cache_read_tokens" \
  -v input_price="${input_price:-0.000003}" \
  -v output_price="${output_price:-0.000015}" \
  -v cache_write_price="${cache_write_price:-0.000003750}" \
  -v cache_read_price="${cache_read_price:-0.000000300}" \
  'BEGIN { printf "%.10f", input * input_price + output * output_price + cache_write * cache_write_price + cache_read * cache_read_price }')

# Accumulate each API turn once. Claude Code can invoke the statusline many
# times without a new turn, so do not add the same current_usage repeatedly.
cost_file="${CLAUDE_COST_FILE:-/tmp/claude-session-cost-$PPID}"
turn_signature="$model:$input_tokens:$output_tokens:$cache_write_tokens:$cache_read_tokens"
state=$(cat "$cost_file" 2>/dev/null || true)
prev=${state%%|*}
last_signature=${state#*|}
[[ "$prev" == "$state" || ! "$prev" =~ ^[0-9]+([.][0-9]+)?$ ]] && prev=0
if [[ "$turn_signature" != "$last_signature" ]]; then
  session_cost=$(awk -v prev="$prev" -v turn="$turn_cost" 'BEGIN { printf "%.10f", prev + turn }')
  printf '%s|%s\n' "$session_cost" "$turn_signature" >"$cost_file"
else
  session_cost="$prev"
fi

sep=$(gum style --foreground="#888888" " | ")
model_s=$(gum style --foreground="#7697d6" "$model")
mode_s=$(gum style --foreground="$mode_color" "$mode_glyph")
model_s="${model_s} ${mode_s}"

if [[ -n "$used" ]]; then
  used_int=$(printf '%.0f' "$used")
  if [[ "$used_int" -ge 85 ]]; then ctx_color="#cf6a4c"
  elif [[ "$used_int" -ge 60 ]]; then ctx_color="#fad07a"
  else ctx_color="#99ad6a"
  fi
  ctx_s=$(gum style --foreground="$ctx_color" "${used_int}%")
fi

turn_s=$(gum style --foreground="#8fbfdc" "~\$$(printf '%.4f' "$turn_cost")")
session_s=$(gum style --foreground="#ffb964" "$(printf '%.4f' "$session_cost")")

out="$model_s"
[[ -n "$ctx_s" ]] && out="${out}${sep}${ctx_s}"
out="${out}${sep}${turn_s}|${session_s}"
printf '%s\n' "$out"
