Here’s the complete `README.md` file—clean, detailed, and user-friendly—explaining how the script works, step-by-step:

````markdown
# 🔥 bulk_delete_tmux_safe.sh — Secure & Resilient S3 Bucket Cleanup

---

## ✅ What It Does

- Safely deletes **multiple S3 buckets**, one at a time.
- Runs inside a **persistent `tmux` session**, so the cleanup continues even if your terminal disconnects.
- Prompts at every stage—folders, root objects, versions, delete markers, and final bucket deletion.
- Stops safely on errors and drops you into `tmux` for quick diagnostics.

---

## 🌟 Why It Matters

- **Large buckets** can take a while to delete—AWS CloudShell may disconnect mid-run.
- With `tmux`, the script keeps running in the background even if you get disconnected.
- The script uses **strict error handling** to prevent silent failures.
- You have full control—**nothing is deleted unless you confirm it**.

---

## 🧭 How It Works (Visual Flow)

```text
You run script
 └─► Is it in tmux?
      ├─ No → restart inside tmux and exit current shell
      └─ Yes → proceed
                ↓
            Enter bucket names (one per line)
                ↓
          For each bucket:
            1. Validate bucket exists → confirm to proceed?
            2. List and confirm deletion of each top-level folder
            3. Show root-level objects → confirm deletion?
            4. List versioned objects & delete markers → confirm deletion for each
            5. Ask final confirmation → delete bucket
                ↓
     If any operation fails → script stops, shows error, and reattaches tmux
                ↓
           “🎯 All done!” after all buckets are processed
````

---

## 🛠 Setup & Usage

1. **Save** the script as `bulk_delete_tmux_safe.sh`.

2. **Install** dependencies in CloudShell:

   ```bash
   sudo yum install -y tmux jq
   ```

3. **Make executable**:

   ```bash
   chmod +x bulk_delete_tmux_safe.sh
   ```

4. **Run**:

   ```bash
   ./bulk_delete_tmux_safe.sh
   ```

   * It will start a `tmux` session automatically.
   * Reconnect anytime with:

     ```bash
     tmux attach -t s3deleter_tmux
     ```

5. **Enter bucket names**, one per line. Press **Enter** on a blank line to start.

6. **Approve each step** via prompts. Nothing is deleted without your “yes.”

7. If an error occurs, you’ll be dropped into `tmux` for quick inspection.

---

## 🧩 Detailed Code Walkthrough

| Section                                       | Purpose                                                                                                                   |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `#!/usr/bin/env bash`<br>`set -Eeuo pipefail` | Enables strict error checking. The script exits on errors or undefined variables.                                         |
| `trap ... ERR`                                | If anything fails, the `on_error` function runs.                                                                          |
| `on_error()`                                  | Prints where the error happened, reattaches tmux for debugging.                                                           |
| `env_check()`                                 | Ensures `aws`, `jq`, and `tmux` are installed before doing anything.                                                      |
| `if [ -z "${TMUX:-}" ]`                       | Detects if the script is running outside tmux—if so, it restarts itself inside tmux.                                      |
| Bucket input loop                             | Reads multiple bucket names interactively until a blank line is entered.                                                  |
| `delete_bucket_safe()`                        | For each bucket: validates existence, lists folders and objects, prompts before deletion, and finally removes the bucket. |
| Version/delete markers handling               | Ensures versioned content is also deleted properly.                                                                       |
| Final confirmation and delete                 | Requires explicit approval before actually deleting the bucket.                                                           |

---

## 💡 Tips & Alternatives

* **Batch input from a file**:

  ```bash
  ./bulk_delete_tmux_safe.sh < buckets.txt
  ```

* **Session logging**:

  Attach to tmux, then run:

  ```bash
  script -f delete.log
  ```

* **Dry-run mode**:

  Prepend `echo` before `aws` commands to simulate changes without deleting.

---

## ✅ Summary

`bulk_delete_tmux_safe.sh` is:

* **Resilient**: survives session disconnections via tmux.
* **Secure**: prompts for confirmation at every destructive step.
* **Safe**: stops on errors and allows immediate retrieval of diagnostics.
* **User-friendly**: simple instructions, clear flow, minimal prerequisites.

Feel free to let me know if you'd like a visual flowchart diagram or additional features like dry-run flags or logging built in!
