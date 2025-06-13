#!/usr/bin/env bash
set -euo pipefail

confirm() {
  while true; do
    read -p "$1 (y/n): " yn
    case $yn in [Yy]* ) return 0;; [Nn]* ) return 1;; * ) echo "Please answer y or n." ;; esac
  done
}

aws_check() {
  if ! command -v aws &>/dev/null; then
    echo "❌ AWS CLI not found. Install it first." >&2
    exit 1
  fi
  aws configure list >/dev/null || { echo "❌ AWS CLI appears unconfigured."; exit 1; }
}

delete_s3_bucket_secure() {
  local bucket="$1"

  aws_check

  aws s3api head-bucket --bucket "$bucket" || { echo "❌ Bucket not found or inaccessible."; return 1; }

  echo "🗑️  Preparing to delete bucket \"$bucket\" safely…"

  # Step 1: List all prefixes ("folders")
  mapfile -t prefixes < <(
    aws s3api list-objects-v2 --bucket "$bucket" --delimiter "/" \
      --query 'CommonPrefixes[].Prefix' --output text
  )

  if [ ${#prefixes[@]} -gt 0 ]; then
    echo "Found ${#prefixes[@]} top‑level folders:"
    for p in "${prefixes[@]}"; do echo " • $p"; done
    echo

    for p in "${prefixes[@]}"; do
      if confirm "Delete all contents under prefix '$p'?"; then
        aws s3 rm "s3://$bucket/$p" --recursive
        echo "→ Deleted s3://$bucket/$p"
      else
        echo "→ Skipped prefix '$p'"
      }
    done
  else
    echo "No folder prefixes found."
  fi

  # Prompt deletion of any remaining root-level objects
  root_objs=$(aws s3api list-objects-v2 --bucket "$bucket" --query 'Contents[].Key' --output text)
  if [ -n "$root_objs" ]; then
    echo -e "\nFound $(wc -w <<<"$root_objs") objects at root level:"
    echo "$root_objs" | head -n 5 | nl -v1
    [ "$(wc -w <<<"$root_objs")" -gt 5 ] && echo " ...and more"
    if confirm "Delete all root-level objects?"; then
      aws s3 rm "s3://$bucket/" --recursive --exclude "*" --include "*"
      echo "→ Deleted all root objects."
    else
      echo "→ Root-level objects preserved."
    fi
  fi

  # Versioned items
  echo -e "\nChecking for versioned/deleted items..."
  for type in "Versions" "DeleteMarkers"; do
    items_json=$(aws s3api list-object-versions --bucket "$bucket" --query "${type}[] | []")
    count=$(jq length <<<"$items_json")
    if (( count > 0 )); then
      echo "Found $count $type."
      echo "$items_json" | jq -r '.[0:5] | .[] | .Key' | nl
      [ "$count" -gt 5 ] && echo " ...and more"
      if confirm "Delete all $type?"; then
        aws s3api delete-objects --bucket "$bucket" \
          --delete "{\"Objects\":$items_json}"
        echo "→ Deleted $type."
      else
        echo "→ Skipped $type."
      fi
    fi
  done

  echo
  if confirm "ARE YOU ABSOLUTELY SURE you want to 🔥 DELETE BUCKET '$bucket' permanently?"; then
    aws s3api delete-bucket --bucket "$bucket"
    echo "✅ Bucket '$bucket' deleted."
  else
    echo "✅ Safe exit—bucket remains intact."
  fi
}

bucket="${1:-}"
if [ -z "$bucket" ]; then
  read -p "Enter bucket name to delete: " bucket
fi
delete_s3_bucket_secure "$bucket"
