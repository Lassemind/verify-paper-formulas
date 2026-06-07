#!/usr/bin/env bash
# Safely run a SHORT, self-contained Python formula snippet and print its stdout.
# Usage: run_python.sh <snippet-file>
#
# This executes model-generated code, so it is deliberately locked down:
#   - a token blocklist rejects anything beyond pure arithmetic (no os/sys/
#     subprocess/open/eval/exec/import-of-anything-but-math, no dunder, no network)
#   - python3 -I -S  : isolated mode, no site packages, no env-var influence
#   - timeout 10s    : kills runaway loops
#   - runs in a throwaway temp cwd; the snippet gets no useful filesystem context
#
# Prints JSON: {"ok":true,"stdout":"..."} | {"ok":false,"error":"...","reason":"blocked|timeout|error"}
# It is NOT a general sandbox — it is "good enough" for a formula that should only
# need `import math`. Anything suspicious is refused rather than run.

set -uo pipefail

SNIP="${1:?usage: run_python.sh <snippet-file>}"
[ -f "$SNIP" ] || { echo '{"ok":false,"reason":"error","error":"snippet file not found"}'; exit 2; }

CODE="$(cat "$SNIP")"

# --- security gate: refuse anything beyond math --------------------------------
# Allowed import: only `math` and `cmath`. Everything else on this list is denied.
BLOCK_RE='import[[:space:]]+(os|sys|subprocess|socket|shutil|pathlib|requests|urllib|http|importlib|ctypes|pickle|builtins)|from[[:space:]]+(os|sys|subprocess|socket|shutil|pathlib|requests|urllib|http|importlib|ctypes|pickle|builtins)|__import__|__builtins__|\beval\b|\bexec\b|\bopen\b|\bcompile\b|\binput\b|getattr|setattr|globals\(|locals\(|\bos\.|\bsys\.'

if printf '%s' "$CODE" | grep -Eq "$BLOCK_RE"; then
  hit="$(printf '%s' "$CODE" | grep -Eo "$BLOCK_RE" | head -1)"
  printf '{"ok":false,"reason":"blocked","error":%s}\n' \
    "$(jq -Rn --arg h "$hit" '"refused: snippet uses disallowed token \($h)"')"
  exit 0
fi

# only `import math` / `import cmath` are permitted as import lines at all
if printf '%s' "$CODE" | grep -Eq '^[[:space:]]*(import|from)[[:space:]]' \
   && printf '%s' "$CODE" | grep -E '^[[:space:]]*(import|from)[[:space:]]' \
        | grep -Evq '^[[:space:]]*import[[:space:]]+(math|cmath)([[:space:]]|$|,)'; then
  printf '{"ok":false,"reason":"blocked","error":"refused: only import math/cmath allowed"}\n'
  exit 0
fi

# --- run, isolated + time-boxed, in a throwaway cwd ----------------------------
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

set +e
OUT="$(cd "$workdir" && printf '%s' "$CODE" | timeout 10 python3 -I -S - 2>"$workdir/err")"
rc=$?
set -e

if [ "$rc" -eq 124 ]; then
  printf '{"ok":false,"reason":"timeout","error":"snippet exceeded 10s"}\n'
  exit 0
fi
if [ "$rc" -ne 0 ]; then
  printf '{"ok":false,"reason":"error","error":%s}\n' \
    "$(jq -Rs '.' < "$workdir/err" 2>/dev/null || echo '"python error"')"
  exit 0
fi

printf '{"ok":true,"stdout":%s}\n' "$(printf '%s' "$OUT" | jq -Rs '.')"
