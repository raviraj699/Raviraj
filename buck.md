Here's a beautifully formatted `README.md` file that explains each part of the script with detailed annotations and insights:

---

## 🗑️ `buck.sh` — Secure AWS S3 Bucket Deletion Script

---

### 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Usage](#usage)
4. [Script Breakdown](#script-breakdown)

   * Shebang & Safety Flags
   * `confirm()` Function
   * `aws_check()` Function
   * `delete_s3_bucket_secure()` Function

     * Bucket Validation
     * Folder (Prefix) Handling
     * Root‑level Object Handling
     * Version/Delete‑Marker Handling
     * Final Bucket Deletion
   * Entry‑Point Guard
5. [Customization & Enhancements](#customization--enhancements)
6. [License & Attribution](#license--attribution)

---

### 🔍 Overview

The `buck.sh` script is designed to **securely and interactively delete an S3 bucket**, ensuring:

* Prompting per folder/prefix
* Safe removal of root-level objects
* Handling of versioned objects and delete markers
* Final confirmation before the bucket itself is deleted

---

### ✅ Prerequisites

* **OS**: Linux / macOS
* **Tools**: `bash`, AWS CLI (properly configured), `jq` (for JSON parsing)
* **Permissions**: IAM permissions to run:

  * `s3:ListBucket`
  * `s3:DeleteObject`
  * `s3:DeleteObjectVersion`
  * `s3:DeleteBucket`

---

### 🚀 Usage

```bash
chmod +x buck.sh
./buck.sh my-s3-bucket-name
```

Follow interactive prompts to approve deletion steps.

---

### 🧠 Script Breakdown

```bash
#!/usr/bin/env bash
set -euo pipefail
```

* **Shebang** ensures bash is used.
* **Flags**:
  `-e`: exit on error
  `-u`: error on undefined variables
  `-o pipefail`: detect failures in piped commands

---

#### ⚠️ `confirm()`

```bash
confirm() {
  while true; do
    read -rp "$1 (y/n): " yn
    case $yn in [Yy]*) return 0 ;; [Nn]*) return 1 ;; *) echo "Please answer y or n." ;; esac
  done
}
```

Reusable function to collect explicit confirmation (`yes/no`). Prevents accidental deletions.

---

#### 🛡️ `aws_check()`

```bash
aws_check() {
  command -v aws >/dev/null || { echo "❌ Install AWS CLI"; exit 1; }
  aws configure list >/dev/null 2>&1 || { echo "❌ Configure AWS CLI"; exit 1; }
}
```

Validates AWS CLI is installed and has valid credentials before proceeding.

---

#### 🗃️ `delete_s3_bucket_secure()`

```bash
delete_s3_bucket_secure() {
  local bucket="$1"
  aws_check
  aws s3api head-bucket --bucket "$bucket" >/dev/null || { echo "❌ Bucket '$bucket' not found."; exit 1; }
  echo "🔐 Safely deleting S3 bucket: $bucket"
```

* Stores bucket name in a local variable
* Checks AWS tool and credentials
* Verifies bucket exists and is accessible

---

##### 📂 Prefix (Folder) Handling

```bash
mapfile -t prefixes < <(
  aws s3api list-objects-v2 --bucket "$bucket" --delimiter "/" \
    --query 'CommonPrefixes[].Prefix' --output text && printf '\0'
)
if ((${#prefixes[@]})); then
  for p in "${prefixes[@]}"; do
    ...
    if confirm "..."; then
      aws s3 rm "s3://$bucket/$p" --recursive
    fi
  done
else
  echo "No folders found."
fi
```

* Retrieves top-level prefixes (folders)
* Prompts whether to delete each folder’s contents

---

##### 🗃️ Root-level Object Handling

```bash
read -r -d '' rootobjs < <(
  aws s3api list-objects-v2 --bucket "$bucket" --query 'Contents[].Key' --output text && printf '\0'
)
if [[ -n "${rootobjs:-}" ]]; then
  ...
  if confirm "Delete all root-level objects?"; then
    aws s3 rm "s3://$bucket/" --recursive
  fi
fi
```

* Fetches keys in the bucket root
* Shows a preview and requests confirmation to clean

---

##### 🔁 Version & Delete Marker Handling

```bash
for typ in Versions DeleteMarkers; do
  items=$(aws s3api list-object-versions --bucket "$bucket" --query "${typ}[] | []")
  ...
  if confirm "Delete all $typ?"; then
    aws s3api delete-objects --bucket "$bucket" --delete "{\"Objects\":${items},\"Quiet\":false}"
  fi
done
```

* Collects versioned objects or delete markers
* Prompts before deleting each type

---

##### 🧹 Final Bucket Deletion

```bash
if confirm "FINAL: Delete bucket '$bucket'? This CANNOT be undone."; then
  aws s3api delete-bucket --bucket "$bucket"
  echo "✅ Bucket deleted."
else
  echo "🛡️ Operation aborted."
fi
```

Ensures final confirmation before deleting the bucket itself. No silent deletions.

---

#### 🎯 Entry-Point Guard

```bash
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -ge 1 ]]; then
    bucket="$1"
  else
    read -rp "Enter the S3 bucket name to delete: " bucket
  fi
  delete_s3_bucket_secure "$bucket"
fi
```

This block makes the script executable and interactive when run directly.

---

### 🛠 Customization & Enhancements

* **Dry-run flag**: Use `--dry-run` to preview actions without executing deletions
* **Logging**: Redirect outputs to a log file for auditing
* **MFA-delete**: Add support for MFA token in `delete-object` calls
* **Error handling**: Retry logic for transient AWS API failures

---

### 📜 License & Attribution

* Written by **Raviraj / Rajcommit**
* Freely modifiable under \[Your Preferred License]

---

🚀 **Happy (and safe) bucket cleaning!**
