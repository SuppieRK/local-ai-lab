#!/bin/bash
set -u
set -o pipefail

usage() {
  cat <<'USAGE'
Purpose:
  Test different combinations of context windows and GPU offload

Usage:
  ./llm_load_benchmark.sh -m <MODEL_ID> [options]

Options:
  -m, --model-id <id>      Target model id (required)
  -u, --api-url <url>      LM Studio base URL (default: http://127.0.0.1:1234)
  -k, --auth-key <key>     Optional bearer key
      --lms-path <path>    Optional LM Studio CLI path override
      --context <int>      Shortcut: set both min/max context to one value
      --min-context <int>  Minimum context length (default: 2048)
      --max-context <int>  Maximum context length (default: 8192)
      --gpu-values <list>  GPU offload ratios CSV (default: 0.6,0.9,max)
      --ttl <seconds>      Model TTL (default: 300)
      --repeats <int>      Repeats per tier (default: 15)
      --max-total-time <s> Stop after N seconds (0 = unlimited)
  -d, --debug              Debug logging
  -h, --help               Show help
USAGE
}

# Defaults
API_URL="http://127.0.0.1:1234"
AUTH_KEY=""
MODEL_ID=""
MIN_CONTEXT=2048
MAX_CONTEXT=8192
GPU_CSV="0.6,0.9,max"
TTL=300
REPEATS=15
MAX_TOTAL_TIME=0
LMS_PATH=""
DEBUG=0

printf -v RUN_ID '%(%Y%m%d%H%M%S)T' -1
printf -v RUN_DT '%(%Y%m%d_%H%M%S)T' -1
TZ=UTC printf -v RUN_TS_UTC '%(%Y-%m-%dT%H:%M:%SZ)T' -1

REQUEST_URL=""
MODELS_URL=""
LMS_BIN=""
MODEL_MAX_CONTEXT=0
EFFECTIVE_MAX_CONTEXT=0

OUT_DIR="03_llm_settings/history"
CSV_FILE=""
PAYLOAD_FILE=""
STOP_REQUESTED=0
CURRENT_LOAD=""
START_EPOCH=0
ACTIVE_CHILD_PID=""

declare -a GPU_VALUES=()
declare -a CONTEXT_VALUES=()
declare -a PROMPT_TEMPLATES=()

log() { printf '%s\n' "$*" >&2; }
debug() { [[ "$DEBUG" -eq 1 ]] && printf '[debug] %s\n' "$*" >&2; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

is_int() { [[ "$1" =~ ^[0-9]+$ ]]; }
calc() { awk "BEGIN{printf \"%.6f\", ($1)}"; }
slug() { printf '%s' "$1" | tr '/:@ ' '----' | tr -cd 'A-Za-z0-9_.-'; }

section() { printf '\n%s\n' "$1"; }

run_stream_cmd() {
  "$@" &
  local pid=$!
  local rc
  ACTIVE_CHILD_PID="$pid"
  wait "$pid"; rc=$?
  ACTIVE_CHILD_PID=""
  return "$rc"
}

headers() {
  HDR=(-H "Content-Type: application/json")
  [[ -n "$AUTH_KEY" ]] && HDR+=(-H "Authorization: Bearer $AUTH_KEY")
}

parse_args() {
  local opt val
  [[ $# -gt 0 ]] || { usage; exit 1; }
  while [[ $# -gt 0 ]]; do
    opt="$1"
    case "$opt" in
      -m|--model-id) val="${2:-}"; MODEL_ID="$val"; shift 2 ;;
      -u|--api-url) val="${2:-}"; API_URL="$val"; shift 2 ;;
      -k|--auth-key) val="${2:-}"; AUTH_KEY="$val"; shift 2 ;;
      --lms-path) val="${2:-}"; LMS_PATH="$val"; shift 2 ;;
      --context) val="${2:-}"; MIN_CONTEXT="$val"; MAX_CONTEXT="$val"; shift 2 ;;
      --min-context) val="${2:-}"; MIN_CONTEXT="$val"; shift 2 ;;
      --max-context) val="${2:-}"; MAX_CONTEXT="$val"; shift 2 ;;
      --gpu-values) val="${2:-}"; GPU_CSV="$val"; shift 2 ;;
      --ttl) val="${2:-}"; TTL="$val"; shift 2 ;;
      --repeats) val="${2:-}"; REPEATS="$val"; shift 2 ;;
      --max-total-time) val="${2:-}"; MAX_TOTAL_TIME="$val"; shift 2 ;;
      -d|--debug) DEBUG=1; shift ;;
      -h|--help|help) usage; exit 0 ;;
      *) die "unknown option: $opt" ;;
    esac
  done
}

validate() {
  [[ -n "$MODEL_ID" ]] || die "--model-id is required"
  is_int "$MIN_CONTEXT" || die "min-context must be int"
  is_int "$MAX_CONTEXT" || die "max-context must be int"
  is_int "$TTL" || die "ttl must be int"
  is_int "$REPEATS" || die "repeats must be int"
  is_int "$MAX_TOTAL_TIME" || die "max-total-time must be int"
  [[ "$MIN_CONTEXT" -le "$MAX_CONTEXT" ]] || die "min context must be <= max context"
  [[ "$REPEATS" -ge 1 ]] || die "repeats must be >= 1"
  for t in curl jq awk; do command -v "$t" >/dev/null 2>&1 || die "missing tool: $t"; done
}

normalize_urls() {
  local b="${API_URL%/}"
  b="${b%/api/v0/chat/completions}"
  b="${b%/api/v1/models}"
  # Using old LM Studio API: https://github.com/lmstudio-ai/lmstudio-bug-tracker/issues/601
  REQUEST_URL="$b/api/v0/chat/completions"
  MODELS_URL="$b/api/v1/models"
}

discover_lms() {
  local p
  if [[ -n "$LMS_PATH" ]]; then
    "$LMS_PATH" --help >/dev/null 2>&1 || die "--lms-path is not runnable: $LMS_PATH"
    LMS_BIN="$LMS_PATH"; debug "using explicit lms path: $LMS_BIN"; return
  fi
  p="$(command -v lms 2>/dev/null || true)"
  if [[ -n "$p" ]] && "$p" --help >/dev/null 2>&1; then LMS_BIN="$p"; debug "using lms from PATH: $LMS_BIN"; return; fi
  if [[ "$(uname -r | tr '[:upper:]' '[:lower:]')" == *microsoft* ]]; then
    for p in /mnt/c/Users/*/.lmstudio/bin/lms.exe; do
      [[ -f "$p" ]] || continue
      if "$p" --help >/dev/null 2>&1; then LMS_BIN="$p"; debug "using lms from WSL probe: $LMS_BIN"; return; fi
    done
  fi
  die "could not find runnable LM Studio CLI; provide --lms-path"
}

preflight_model() {
  debug "GET $MODELS_URL"
  local json
  json="$(curl -sS -m 20 -X GET "$MODELS_URL" "${HDR[@]}")" || die "failed to query $MODELS_URL"
  MODEL_MAX_CONTEXT="$(jq -er --arg m "$MODEL_ID" '
    first(
      .models[] | select(.key==$m and .type=="llm") |
      (.max_context_length // 0 | tostring)
    )
  ' <<< "$json" 2>/dev/null)" || die "model '$MODEL_ID' not found or invalid models response from $MODELS_URL"
  EFFECTIVE_MAX_CONTEXT="$MAX_CONTEXT"
  if is_int "$MODEL_MAX_CONTEXT" && [[ "$MODEL_MAX_CONTEXT" -gt 0 ]] && [[ "$MODEL_MAX_CONTEXT" -lt "$EFFECTIVE_MAX_CONTEXT" ]]; then
    EFFECTIVE_MAX_CONTEXT="$MODEL_MAX_CONTEXT"
  fi
  [[ "$MIN_CONTEXT" -le "$EFFECTIVE_MAX_CONTEXT" ]] || die "min context exceeds effective max"
}

prepare_csv() {
  mkdir -p "$OUT_DIR"
  CSV_FILE="$OUT_DIR/${RUN_DT}_$(slug "$MODEL_ID").csv"
  cat > "$CSV_FILE" <<'CSV'
run_id,run_ts_utc,model_id,context_length,gpu_offload,repeats,total_requests,successful_requests,success_rate,avg_time_to_first_byte_ms,avg_total_s,avg_output_tps_e2e,completion_tokens_total
CSV
}

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

build_prompt_templates() {
  PROMPT_TEMPLATES=(
    "Reply exactly with: System ready. Then add one short sentence."
    "$(printf 'benchmark-token %0.s' {1..80}) Write 2 concise bullets with action-oriented wording."
    "$(printf 'benchmark-token %0.s' {1..200}) Write a compact 3-bullet summary."
  )
}

build_payload_file() {
  local tmp_file
  tmp_file="$(mktemp)"
  PAYLOAD_FILE="$tmp_file"

  local -a schedule=()
  local i r n j tmp tier_idx

  # Build an even tier mix and shuffle it once per run.
  for i in 0 1 2; do
    for ((r=1; r<=REPEATS; r++)); do
      schedule+=("$i")
    done
  done
  for ((n=${#schedule[@]}-1; n>0; n--)); do
    j=$((RANDOM % (n + 1)))
    tmp="${schedule[n]}"
    schedule[n]="${schedule[j]}"
    schedule[j]="$tmp"
  done

  # Store prompts with a candidate placeholder to avoid rewriting large payload strings repeatedly.
  for n in "${!schedule[@]}"; do
    tier_idx="${schedule[$n]}"
    printf '%s [ID:%s-c__CID__-mix%s-t%s]\n' \
      "${PROMPT_TEMPLATES[$tier_idx]}" \
      "$RUN_ID" \
      "$((n+1))" \
      "$((tier_idx+1))" >> "$PAYLOAD_FILE"
  done
}

build_values() {
  IFS=',' read -r -a GPU_VALUES <<< "${GPU_CSV//[[:space:]]/}"
  local gpu_value
  for gpu_value in "${GPU_VALUES[@]}"; do
    [[ -n "$gpu_value" ]] || die "empty value in --gpu-values"
  done

  CONTEXT_VALUES=()
  local p=1
  while [[ "$p" -lt "$MIN_CONTEXT" ]]; do p=$((p*2)); done
  while [[ "$p" -le "$EFFECTIVE_MAX_CONTEXT" ]]; do CONTEXT_VALUES+=("$p"); p=$((p*2)); done
  [[ ${#CONTEXT_VALUES[@]} -gt 0 ]] || CONTEXT_VALUES=("$MIN_CONTEXT")
  [[ "${CONTEXT_VALUES[0]}" -eq "$MIN_CONTEXT" ]] || CONTEXT_VALUES=("$MIN_CONTEXT" "${CONTEXT_VALUES[@]}")
  local last=$(( ${#CONTEXT_VALUES[@]} - 1 ))
  [[ "${CONTEXT_VALUES[$last]}" -eq "$EFFECTIVE_MAX_CONTEXT" ]] || CONTEXT_VALUES+=("$EFFECTIVE_MAX_CONTEXT")
}

load_model() { run_stream_cmd "$LMS_BIN" load "$MODEL_ID" --local -y --parallel 1 --context-length "$1" --ttl "$TTL" --gpu "$2"; }
unload_model() { "$LMS_BIN" unload "$MODEL_ID" >/dev/null 2>&1 || true; }

request_completion() {
  local prompt="$1" body payload http completion_token_count tps parsed \
    time_to_first_byte_ms generation_time esc_prompt
  esc_prompt="$(json_escape "$prompt")"
  body="{\"model\":\"$MODEL_ID\",\"messages\":[{\"role\":\"user\",\"content\":\"$esc_prompt\"}],\"max_tokens\":128,\"stream\":false}"
  payload="$(curl -sS -m 90 -X POST "$REQUEST_URL" "${HDR[@]}" -d "$body" -w $'\n__HTTP_CODE__%{http_code}')" || {
    if [[ "$STOP_REQUESTED" -eq 1 ]]; then
      echo "ERR|interrupted|0|0|0|0"
    else
      echo "ERR|curl failed|0|0|0|0"
    fi
    return
  }
  http="${payload##*__HTTP_CODE__}"
  payload="${payload%$'\n'__HTTP_CODE__*}"
  if [[ ! "$http" =~ ^2 ]]; then
    echo "ERR|$(echo "$payload" | jq -r '.error.message // .message // \"http error\"' 2>/dev/null)|0|0|0|0"
    return
  fi
  parsed="$(echo "$payload" | jq -er '
    if (.choices | type == "array" and length > 0)
      and ((.usage.completion_tokens // 0) > 0)
      and ((.stats.time_to_first_token // 0) > 0)
      and ((.stats.tokens_per_second // 0) > 0)
      and ((.stats.generation_time // 0) > 0)
    then
      [ .usage.completion_tokens
      , (.stats.time_to_first_token * 1000)
      , .stats.tokens_per_second
      , .stats.generation_time ] | @tsv
    else empty end
  ' 2>/dev/null)" || { echo "ERR|missing required LM Studio stats in response|0|0|0|0"; return; }
  IFS=$'\t' read -r completion_token_count time_to_first_byte_ms tps generation_time <<< "$parsed"
  echo "OK|$time_to_first_byte_ms|$generation_time|$completion_token_count|$tps"
}

run_candidate() {
  local idx="$1" total="$2" ctx="$3" gpu="$4"
  log "[$idx/$total] Running candidate: ctx=$ctx gpu=$gpu"

  local successful_request_count=0 completion_token_total=0 calls=$((3*REPEATS))
  local out status time_to_first_byte_ms total_s completion_token_count tps prompt
  local ok_lines=""

  while IFS= read -r prompt; do
    [[ "$STOP_REQUESTED" -eq 1 ]] && break
    prompt="${prompt/__CID__/$idx}"
    out="$(request_completion "$prompt")"
    IFS='|' read -r status time_to_first_byte_ms total_s completion_token_count tps <<< "$out"
    if [[ "$status" == "OK" ]]; then
      successful_request_count=$((successful_request_count + 1))
      completion_token_total=$((completion_token_total + completion_token_count))
      ok_lines+="$time_to_first_byte_ms $tps $total_s"$'\n'
    fi
  done < "$PAYLOAD_FILE"

  local success_rate average_first_byte_ms average_output_tps average_total_seconds
  success_rate="$(calc "$successful_request_count/$calls")"
  if [[ "$successful_request_count" -gt 0 ]]; then
    read -r average_first_byte_ms average_output_tps average_total_seconds < <(
      awk '{first_byte+=$1; output_tps+=$2; total_time+=$3; n+=1} END {if(n>0) printf "%.6f %.6f %.6f\n", first_byte/n, output_tps/n, total_time/n; else printf "0.000000 0.000000 0.000000\n"}' <<< "$ok_lines"
    )
  else
    average_first_byte_ms="0"; average_output_tps="0"; average_total_seconds="0"
  fi
  # Persist one aggregated CSV row per candidate (not per individual request).
  printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
    "$RUN_ID" \
    "$RUN_TS_UTC" \
    "$MODEL_ID" \
    "$ctx" \
    "$gpu" \
    "$REPEATS" \
    "$calls" \
    "$successful_request_count" \
    "$success_rate" \
    "$average_first_byte_ms" \
    "$average_total_seconds" \
    "$average_output_tps" \
    "$completion_token_total" >> "$CSV_FILE"
}

print_summary() {
  section "Benchmark Start"
  cat <<EOF
Running benchmark
  Model: $MODEL_ID
  API: $API_URL
  LMS CLI: $LMS_BIN
  Context range: $MIN_CONTEXT..$EFFECTIVE_MAX_CONTEXT (model max=$MODEL_MAX_CONTEXT)
  GPU values: $GPU_CSV
  Repeats per tier: $REPEATS
  TTL: $TTL seconds
  Max total time: $MAX_TOTAL_TIME (0=unlimited)
  CSV output: $CSV_FILE
EOF
}

print_results() {
  [[ -s "$CSV_FILE" ]] || { log "No candidate results were produced."; return; }
  section "Candidate Results"
  printf "%8s | %6s | %15s | %13s | %17s | %8s | %8s\n" \
    "Context" "GPU" "First Byte (ms)" "Avg Total (s)" "Output TPS (e2e)" "Success" "Rank"
  printf "%8s-+-%6s-+-%15s-+-%13s-+-%17s-+-%8s-+-%8s\n" \
    "--------" "------" "---------------" "-------------" "-----------------" "--------" "--------"

  local rendered
  rendered="$(awk -F',' '
    NR>1 && NF>0 {
      rows[++n] = $0
      # Key: Success (desc), TPS (desc), First Byte (asc), Original Index.
      keyed[n] = sprintf("%012.6f|%012.6f|%012.6f|%d", 1000000-$9, 1000000-$12, $10, n)
    }
    END {
      if (n==0) exit
      asort(keyed)
      for (r=1; r<=n; r++) { split(keyed[r], k, "|"); rank[k[4]+0] = r }
      for (i=1; i<=n; i++) {
        split(rows[i], f, ",")
        printf "%8s | %6s | %15.0f | %13.3f | %17.2f | %8.2f | %8d\n", f[4], f[5], f[10]+0, f[11]+0, f[12]+0, f[9]+0, rank[i]
      }
    }
  ' "$CSV_FILE")"
  printf '%s\n' "$rendered"
}

finalize() {
  [[ -n "$CURRENT_LOAD" ]] && unload_model
  if [[ -n "$PAYLOAD_FILE" ]] && [[ -f "$PAYLOAD_FILE" ]]; then
    rm -f "$PAYLOAD_FILE"
    PAYLOAD_FILE=""
  fi
  print_results
  echo
  if [[ "$STOP_REQUESTED" -eq 1 ]]; then
    log "Benchmark interrupted; partial results saved to: $CSV_FILE"
    exit 130
  fi
  log "Benchmark complete. Results saved to: $CSV_FILE"
  exit 0
}

main() {
  parse_args "$@"
  validate
  normalize_urls
  headers
  discover_lms
  preflight_model
  prepare_csv
  build_values
  build_prompt_templates
  build_payload_file
  trap 'STOP_REQUESTED=1; log "Termination signal received; stopping after current operation..."; if [[ -n "$ACTIVE_CHILD_PID" ]] && kill -0 "$ACTIVE_CHILD_PID" 2>/dev/null; then kill -TERM "$ACTIVE_CHILD_PID" 2>/dev/null || true; fi' INT TERM

  START_EPOCH="$SECONDS"
  print_summary

  local context_count="${#CONTEXT_VALUES[@]}"
  local gpu_count="${#GPU_VALUES[@]}"
  local total=$((context_count * gpu_count))
  local idx=0 ctx gpu
  for ctx in "${CONTEXT_VALUES[@]}"; do
    for gpu in "${GPU_VALUES[@]}"; do
      idx=$((idx+1))
      [[ "$STOP_REQUESTED" -eq 1 ]] && break 2

      if [[ "$MAX_TOTAL_TIME" -gt 0 ]]; then
        local elapsed=$(( SECONDS - START_EPOCH ))
        if [[ "$elapsed" -ge "$MAX_TOTAL_TIME" ]]; then
          log "Reached --max-total-time=${MAX_TOTAL_TIME}s; stopping run."
          STOP_REQUESTED=1
          break 2
        fi
      fi

      log "[$idx/$total] Loading model: ctx=$ctx gpu=$gpu"
      if ! load_model "$ctx" "$gpu"; then
        log "Load failed; skipping candidate ctx=$ctx gpu=$gpu"
        continue
      fi
      CURRENT_LOAD="$ctx|$gpu"

      run_candidate "$idx" "$total" "$ctx" "$gpu"
      unload_model
      CURRENT_LOAD=""
    done
  done

  finalize
}

main "$@"
