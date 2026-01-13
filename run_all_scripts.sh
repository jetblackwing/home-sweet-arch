#!/usr/bin/env bash
set -uo pipefail

show_usage() {
  cat <<EOF
Usage: $0 [OPTIONS] [DIR]

Options:
  -n, --dry-run    Show what would be run, do not execute
  -y, --yes        Run without prompting
      --binaries   Allow running ELF/binary executables (off by default)
  -h, --help       Show this help

If DIR is omitted, the current directory is used. Only non-recursive files
that are executable will be considered. By default ELF binaries are skipped.
EOF
}

dry_run=0
auto_yes=0
allow_binaries=0
dir="."

while [[ ${#} -gt 0 ]]; do
  case "$1" in
    -n|--dry-run) dry_run=1; shift ;;
    -y|--yes) auto_yes=1; shift ;;
    --binaries) allow_binaries=1; shift ;;
    -h|--help) show_usage; exit 0 ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1"; show_usage; exit 2 ;;
    *) dir="$1"; shift ;;
  esac
done

if [[ ! -d "$dir" ]]; then
  echo "Directory not found: $dir" >&2
  exit 2
fi

mapfile -t scripts < <(find "$dir" -maxdepth 1 -type f -executable -print0 | xargs -0 -n1 printf '%s\n' | sort)

filtered=()
for f in "${scripts[@]}"; do
  # Skip self
  if [[ $(realpath "$f") == $(realpath "$0") ]]; then
    continue
  fi

  file_desc=$(file -b -- "$f" 2>/dev/null || true)
  if [[ $allow_binaries -eq 0 && "$file_desc" == *ELF* ]]; then
    echo "Skipping binary: $f"
    continue
  fi

  first_line=$(head -n1 -- "$f" 2>/dev/null || true)
  if [[ "$first_line" =~ ^#! ]]; then
    filtered+=("$f")
  else
    if [[ "$file_desc" == *shell*script* ]] || [[ "$file_desc" == *text* ]]; then
      filtered+=("$f")
    else
      echo "Skipping (no shebang): $f"
    fi
  fi
done

if [[ ${#filtered[@]} -eq 0 ]]; then
  echo "No runnable scripts found in: $dir"
  exit 0
fi

fail_count=0
succ_count=0

echo "Found ${#filtered[@]} scripts to consider."

for f in "${filtered[@]}"; do
  echo
  echo "==> $f"
  if [[ $dry_run -eq 1 ]]; then
    echo "[dry-run] Would execute: $f"
    continue
  fi

  if [[ $auto_yes -eq 0 ]]; then
    read -r -p "Run this script? [y/N] " ans
    case "$ans" in
      [yY]|[yY][eE][sS]) ;;
      *) echo "Skipping $f"; continue ;;
    esac
  fi

  echo "Running in subshell: $f"
  (cd "$dir" && exec "$f")
  rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "Script exited with status $rc"
    ((fail_count++))
  else
    echo "Script completed: OK"
    ((succ_count++))
  fi
done

echo
echo "Summary: succeeded=${succ_count}, failed=${fail_count}, total=${#filtered[@]}"

if [[ $fail_count -ne 0 ]]; then
  exit 1
fi

exit 0
