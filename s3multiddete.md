# S3Deleter Bash Script: Annotated Documentation

## 💻 Overview

This bash script provides a **safe and interactive way to delete AWS S3 buckets** using `tmux` to run the session persistently and log everything.

It ensures safety checks, prompts for user confirmation, and allows you to recover in case of failure.

---

## 🔢 Key Features

* **tmux integration**: Keeps session alive even if the terminal disconnects.
* **Safety first**: Confirmations before deleting folders, objects, versions, and the bucket itself.
* **Dependency check**: Ensures required tools (`aws`, `jq`, `tmux`) are installed.
* **Interactive**: Bucket names and deletion confirmations are user-driven.

---

## 🔧 Script Breakdown

### 1. Shebang and Strict Modes

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
trap 'on_error $? $LINENO' ERR
```

* Enables strict mode: exit on error (`-e`), unset variables (`-u`), and pipeline failure detection (`-o pipefail`).
* `trap` calls `on_error` on any error.

### 2. Variables and Logging

```bash
SESSION="s3deleter_tmux"
LOGFILE="$HOME/${SESSION}_$(date +%Y%m%d_%H%M%S).log"
```

* `SESSION`: The tmux session name.
* `LOGFILE`: Stores timestamped logs.

### 3. Error Handling

```bash
on_error() {
  echo >&2
  echo "❌ ERROR: Command failed at line $2 with exit code $1." >&2
  echo "➡️ Attaching tmux session for diagnostics:"
  tmux attach -t "$SESSION" || true
  exit "$1"
}
```

* On error, prints a message and attaches to the tmux session.

### 4. Confirmation Prompt

```bash
confirm() { ... }
```

* Waits for a `y/n` input (timeout: 120s).
* Used before any destructive operation.

### 5. Environment Check

```bash
env_check() {
  for cmd in aws jq tmux; do
    command -v "$cmd" >/dev/null || { echo "❌ Required tool '$cmd' is missing."; exit 1; }
  done
}
```

* Ensures AWS CLI, jq, and tmux are installed.

### 6. Bucket Deletion Function

```bash
delete_bucket_safe() { ... }
```

Handles deletion in steps:

* **Checks bucket exists**
* **Asks before deleting folders (prefixes)**
* **Optionally removes root-level objects**
* **Handles object versions & delete markers**
* **Final confirmation before deleting the bucket**

### 7. Main Logic

```bash
main() { ... }
```

* Calls `env_check`
* Launches in `tmux` if not already in one
* Collects bucket names interactively
* Calls `delete_bucket_safe` for each

### 8. tmux Integration

```bash
if [ -z "${TMUX:-}" ]; then
  ...
fi
```

* If not inside tmux, launches a new session and reruns script inside it.

---

## 📊 Usage

```bash
chmod +x s3deleter.sh
./s3deleter.sh
```

### Inside Script:

1. Enter bucket names when prompted (one per line).
2. Confirm each step of deletion manually.
3. Review logs saved at `$HOME/s3deleter_tmux_<timestamp>.log`

---

## ⚠️ Safety Notes

* Always test with **non-production buckets first**.
* Ensure proper **IAM permissions**.
* Be cautious: `aws s3 rm` and `aws s3api delete-bucket` are **irreversible**.

---

## 🌟 Final Thoughts

This script offers a robust, interactive, and user-friendly way to clean up S3 buckets. By combining best practices like tmux usage, error trapping, and confirmations, it minimizes accidental deletions while remaining powerful.

---

**Author**: *You*

**Last Updated**: `$(date)`
