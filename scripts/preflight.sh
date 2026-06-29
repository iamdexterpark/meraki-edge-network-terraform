#!/usr/bin/env bash
# preflight.sh — verify the toolchain needed to validate this repo's deliverable.
# Prints the install command for anything missing, then exits non-zero. (F4)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
missing=0

need() { # need <bin> <install-hint>
  if command -v "$1" >/dev/null 2>&1; then
    echo "  ✓ $1"
  else
    echo "  ✗ $1 not found — install: $2" >&2
    missing=1
  fi
}

want() { # want <bin> <install-hint>  (optional: warn, never fail)
  if command -v "$1" >/dev/null 2>&1; then
    echo "  ✓ $1"
  else
    echo "  — $1 not found (optional) — install when needed: $2"
  fi
}

# Always needed.
need python3 "brew install python3"

# Deliverable-specific.
if [ -d manifests ]; then
  need kustomize "brew install kustomize"
  want kubectl   "brew install kubectl   # needed to apply, not to build"
elif [ -d terraform ]; then
  # Either engine satisfies the HCL toolchain (the deliverable targets the common surface).
  if command -v tofu >/dev/null 2>&1; then
    echo "  ✓ tofu (OpenTofu)"
  elif command -v terraform >/dev/null 2>&1; then
    echo "  ✓ terraform"
  else
    echo "  ✗ no HCL engine found — install: brew install opentofu  (or: brew install terraform)" >&2
    missing=1
  fi
fi

[ "$missing" -eq 0 ] && echo "✓ preflight clean" || exit 1
