#!/usr/bin/env bash
set -euo pipefail

# Confirm prompt
confirm() {
  while true; do
    read -rp "$1 (y/n): " yn
    case $yn in [Yy]*) return 0 ;; [Nn]*) return 1 ;; *) echo "Please answer y or n." ;; esac
  done
}

# Check AWS CLI and config
aws_check() {
  command -v aws >/dev/null || { echo "❌ Install AWS CLI"; exit 1; }
  aws configure list >/dev/null 2>&1 || { echo "❌ Configure AWS CLI"; exit 1; }
}

delete_s3_bucket_secure() {
  local bucket="$1"
  aws_check
  aws s3api head-bucket --bucket "$bucket" >/dev/null || { echo "❌ Bucket '$bucket' not found."; exit 1; }
  echo "🔐 Safely deleting S3 bucket: $bucket"

  # List prefixes
  IFS=$'\n' read -r -d '' -a prefixes < <(
    aws s3api list-objects-v2 --bucket "$bucket" --delimiter "/" \
      --query 'CommonPrefixes[].Prefix' --output text && printf '\0'
  )
  if ((${#prefixes[@]})); then
    echo "Found ${#prefixes[@]} folders:"
    for p in "${prefixes[@]}"; do
      echo " • $p"
      if confirm "Delete contents under '$p'?"; then
        aws s3 rm "s3://$bucket/$p" --recursive
        echo "✔️ Deleted '$p'"
      else
        echo "✖️ Skipped '$p'"
      fi
    done
  else
    echo "No folders found."
  fi

  # Root-level objects
  read -r -d '' rootobjs < <(
    aws s3api list-objects-v2 --bucket "$bucket" --query 'Contents[].Key' --output text && printf '\0'
  )
  if [[ -n "${rootobjs:-}" ]]; then
    echo -e "\nFound root-level objects:"
    printf "%s\n" "${rootobjs}" | head -n5
    if confirm "Delete all root-level objects?"; then
      aws s3 rm "s3://$bucket/" --recursive
      echo "✔️ Root objects deleted."
    else
      echo "✖️ Left root objects."
    fi
  fi

  # Versions & delete markers
  for typ in Versions DeleteMarkers; do
    items=$(aws s3api list-object-versions --bucket "$bucket" --query "${typ}[] | []")
    count=$(jq length <<<"$items")
    if (( count > 0 )); then
      echo -e "\nFound $count $typ."
      jq -r '.[0:5][] | .Key' <<<"$items"
      if confirm "Delete all $typ?"; then
        aws s3api delete-objects --bucket "$bucket" --delete "{\"Objects\":${items},\"Quiet\":false}"
        echo "✔️ Deleted $typ."
      else
        echo "✖️ Kept $typ."
      fi
    fi
  done

  echo
  if confirm "FINAL: Delete bucket '$bucket'? This CANNOT be undone."; then
    aws s3api delete-bucket --bucket "$bucket"
    echo "✅ Bucket deleted."
  else
    echo "🛡️ Operation aborted. Bucket preserved."
  fi
}

# Entry point
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -ge 1 ]]; then
    bucket="$1"
  else
    read -rp "Enter S3 bucket name to delete: " bucket
  fi
  delete_s3_bucket_secure "$bucket"
fi
