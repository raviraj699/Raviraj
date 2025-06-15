#!/usr/bin/env bash
set -Eeuo pipefail
trap 'on_error $? $LINENO' ERR

SESSION="s3deleter_tmux"
LOGFILE="$HOME/${SESSION}_$(date +%Y%m%d_%H%M%S).log"

on_error() {
  echo >&2
  echo "❌ ERROR: Command failed at line $2 with exit code $1." >&2
  echo "➡️ Attaching tmux session for diagnostics:"
  tmux attach -t "$SESSION" || true
  exit "$1"
}

confirm() {
  while true; do
    read -rp "$1 (y/n): " -t 120 yn || { echo -e "\n⏳ Timeout. Skipping."; return 1; }
    case $yn in [Yy]*) return 0 ;; [Nn]*) return 1 ;; *) echo "Please answer y or n." ;; esac
  done
}

env_check() {
  for cmd in aws jq tmux; do
    command -v "$cmd" >/dev/null || { echo "❌ Required tool '$cmd' is missing."; exit 1; }
  done
}

delete_bucket_safe() {
  local bucket="$1"
  echo
  echo "🔄 Starting bucket: $bucket"

  aws s3api head-bucket --bucket "$bucket" >/dev/null

  confirm "Proceed deleting bucket '$bucket'?" || { echo "→ Skipped $bucket"; return; }

  mapfile -t prefixes < <(
    aws s3api list-objects-v2 --bucket "$bucket" --delimiter "/" \
      --query 'CommonPrefixes[].Prefix' --output text
  )
  for p in "${prefixes[@]}"; do
    confirm "  Delete folder '$p'?" && \
      aws s3 rm "s3://$bucket/$p" --recursive && echo "    ✅ Deleted $p"
  done

  root_objs=$(aws s3api list-objects-v2 --bucket "$bucket" --query 'Contents[].Key' --output text || true)
  if [[ -n "${root_objs:-}" ]]; then
    echo "  Root-object preview:"
    printf '%s\n' "${root_objs}" | head -n5
    confirm "  Delete all root-level objects?" && \
      aws s3 rm "s3://$bucket/" --recursive && echo "    ✅ Root objects deleted"
  fi

  for typ in Versions DeleteMarkers; do
    items=$(aws s3api list-object-versions --bucket "$bucket" --query "${typ}[] | []")
    count=$(jq length <<<"$items")
    if (( count )); then
      echo "  Found $count $typ"
      jq -r '.[0:3][] | .Key' <<<"$items"
      confirm "  Delete all $typ?" && \
        aws s3api delete-objects --bucket "$bucket" \
          --delete "{\"Objects\":${items},\"Quiet\":false}" \
        && echo "    ✅ Deleted $typ"
    fi
  done

  confirm "🔥 FINAL: Delete bucket '$bucket'?" && \
    aws s3api delete-bucket --bucket "$bucket" && echo "    ✅ Bucket deleted"
  echo "✔️ Done with $bucket"
}

main() {
  env_check

  if [ -z "${TMUX:-}" ]; then
    if tmux has-session -t "$SESSION" 2>/dev/null; then
      echo "⚠️ tmux session '$SESSION' already exists."
      echo "➡️ Attaching to it..."
      tmux attach -t "$SESSION"
      exit 0
    fi
    echo "🔵 Launching tmux session '$SESSION'..."
    tmux new-session -d -s "$SESSION" "bash $0 $* | tee -a '$LOGFILE'"
    echo "✅ Script is now running in tmux. Use: tmux attach -t $SESSION"
    exit 0
  fi

  echo "📥 Enter bucket names (one per line). Blank line to finish:"
  buckets=()
  while read -rp "> " name && [[ -n "$name" ]]; do
    buckets+=("$name")
  done

  [[ ${#buckets[@]} -gt 0 ]] || { echo "❌ No buckets provided. Exiting."; exit 1; }

  for b in "${buckets[@]}"; do
    delete_bucket_safe "$b"
  done

  echo
  echo "🎯 All done!"
}

main "$@"
