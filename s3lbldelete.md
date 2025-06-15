Sure! Below is a full `README.md` file that **explains each line of your script line-by-line**:

---

````markdown
# 🧠 Line-by-Line Explanation: `s3-deleter.sh`

This document explains what each line in the `s3-deleter.sh` script does.

---

## 📝 Script Start

```bash
#!/usr/bin/env bash
````

* Shebang line: tells the OS to run the script using the `bash` interpreter.

```bash
set -Eeuo pipefail
```

* Enables strict error handling:

  * `-E`: ensures traps are inherited.
  * `-e`: exit on any command failure.
  * `-u`: error on use of undefined variables.
  * `-o pipefail`: a pipeline fails if any command fails.

```bash
trap 'on_error $? $LINENO' ERR
```

* Runs `on_error()` function if any command fails. Passes the exit code and line number.

---

## 🖥️ Globals

```bash
SESSION="s3deleter_tmux"
LOGFILE="$HOME/${SESSION}_$(date +%Y%m%d_%H%M%S).log"
```

* `SESSION`: Name of the `tmux` session.
* `LOGFILE`: Log file named with timestamp and saved in home directory.

---

## ❌ Error Handler

```bash
on_error() {
  echo >&2
  echo "❌ ERROR: Command failed at line $2 with exit code $1." >&2
  echo "➡️ Attaching tmux session for diagnostics:"
  tmux attach -t "$SESSION" || true
  exit "$1"
}
```

* Prints error message with line number and exit code.
* Attaches to the `tmux` session for debugging.
* Ensures script exits with the original error code.

---

## ❓ Confirmation Prompt

```bash
confirm() {
  while true; do
    read -rp "$1 (y/n): " -t 120 yn || { echo -e "\n⏳ Timeout. Skipping."; return 1; }
    case $yn in [Yy]*) return 0 ;; [Nn]*) return 1 ;; *) echo "Please answer y or n." ;; esac
  done
}
```

* Prompts user to confirm with `y/n`.
* Times out after 120 seconds.
* Loops until valid input is received.

---

## ✅ Environment Check

```bash
env_check() {
  for cmd in aws jq tmux; do
    command -v "$cmd" >/dev/null || { echo "❌ Required tool '$cmd' is missing."; exit 1; }
  done
}
```

* Ensures required CLI tools (`aws`, `jq`, `tmux`) are installed.

---

## 🪣 Safe Bucket Deletion

```bash
delete_bucket_safe() {
  local bucket="$1"
```

* Starts a function to handle deletion for one bucket.

```bash
  echo "🔄 Starting bucket: $bucket"
  aws s3api head-bucket --bucket "$bucket" >/dev/null
```

* Prints current bucket name.
* Checks if bucket exists.

```bash
  confirm "Proceed deleting bucket '$bucket'?" || { echo "→ Skipped $bucket"; return; }
```

* Confirms before deleting the bucket. Skips if declined.

---

### 📁 Delete Folder Prefixes

```bash
  mapfile -t prefixes < <(
    aws s3api list-objects-v2 --bucket "$bucket" --delimiter "/" \
      --query 'CommonPrefixes[].Prefix' --output text
  )
```

* Fetches all folder-like prefixes and saves into an array `prefixes`.

```bash
  for p in "${prefixes[@]}"; do
    confirm "  Delete folder '$p'?" && \
      aws s3 rm "s3://$bucket/$p" --recursive && echo "    ✅ Deleted $p"
  done
```

* Iterates over folders and confirms before recursive deletion.

---

### 📄 Root-Level Object Deletion

```bash
  root_objs=$(aws s3api list-objects-v2 --bucket "$bucket" --query 'Contents[].Key' --output text || true)
```

* Lists top-level (non-folder) objects.

```bash
  if [[ -n "${root_objs:-}" ]]; then
    echo "  Root-object preview:"
    printf '%s\n' "${root_objs}" | head -n5
    confirm "  Delete all root-level objects?" && \
      aws s3 rm "s3://$bucket/" --recursive && echo "    ✅ Root objects deleted"
  fi
```

* Previews and confirms before deleting all root-level objects.

---

### 🧾 Versioned Object Deletion

```bash
  for typ in Versions DeleteMarkers; do
    items=$(aws s3api list-object-versions --bucket "$bucket" --query "${typ}[] | []")
    count=$(jq length <<<"$items")
```

* Loops through object `Versions` and `DeleteMarkers`.

```bash
    if (( count )); then
      echo "  Found $count $typ"
      jq -r '.[0:3][] | .Key' <<<"$items"
```

* Shows count and a preview of 3 item keys.

```bash
      confirm "  Delete all $typ?" && \
        aws s3api delete-objects --bucket "$bucket" \
          --delete "{\"Objects\":${items},\"Quiet\":false}" \
        && echo "    ✅ Deleted $typ"
    fi
  done
```

* Confirms and deletes all items in the batch.

---

### 🪓 Final Bucket Deletion

```bash
  confirm "🔥 FINAL: Delete bucket '$bucket'?" && \
    aws s3api delete-bucket --bucket "$bucket" && echo "    ✅ Bucket deleted"
  echo "✔️ Done with $bucket"
}
```

* Asks for final confirmation before removing the bucket itself.

---

## 🔁 Main Logic

```bash
main() {
  env_check
```

* First step: check tools are installed.

```bash
  if [ -z "${TMUX:-}" ]; then
```

* If not running inside a tmux session:

```bash
    if tmux has-session -t "$SESSION" 2>/dev/null; then
      echo "⚠️ tmux session '$SESSION' already exists."
      echo "➡️ Attaching to it..."
      tmux attach -t "$SESSION"
      exit 0
    fi
```

* If a session exists, attach to it.

```bash
    echo "🔵 Launching tmux session '$SESSION'..."
    tmux new-session -d -s "$SESSION" "bash $0 $* | tee -a '$LOGFILE'"
    echo "✅ Script is now running in tmux. Use: tmux attach -t $SESSION"
    exit 0
  fi
```

* Otherwise, start a new tmux session, log output, and exit the parent shell.

---

## 🧾 Read Bucket Names

```bash
  echo "📥 Enter bucket names (one per line). Blank line to finish:"
  buckets=()
  while read -rp "> " name && [[ -n "$name" ]]; do
    buckets+=("$name")
  done
```

* Asks user to input S3 bucket names one by one.

```bash
  [[ ${#buckets[@]} -gt 0 ]] || { echo "❌ No buckets provided. Exiting."; exit 1; }
```

* Exit if no buckets were entered.

---

## 🧹 Process Each Bucket

```bash
  for b in "${buckets[@]}"; do
    delete_bucket_safe "$b"
  done
```

* Calls the safe deletion function for each entered bucket.

```bash
  echo
  echo "🎯 All done!"
}
```

* Prints completion message.

---

## 🚀 Entry Point

```bash
main "$@"
```

* Runs the main function, passing all script arguments.

---

## ✅ Summary

This script:

* Protects against accidental deletions using confirmations.
* Handles disconnected terminals using `tmux`.
* Logs all actions for auditing.
* Supports both versioned and non-versioned S3 buckets.

```

---

Would you like this also saved as a `.md` file for download or GitHub use?
```
