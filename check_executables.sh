#!/usr/bin/env bash
set -euo pipefail

dir="${1:-.}"
err=0

printf "Checking executables in: %s\n" "$dir"

while IFS= read -r -d '' f; do
  printf "\n== %s ==\n" "$f"
  file_desc=$(file -b "$f" || true)
  printf "Type: %s\n" "$file_desc"

  if [[ "$file_desc" == *ELF* ]]; then
    if ! command -v ldd >/dev/null 2>&1; then
      echo "ldd not found; skipping shared-library check"
    else
      echo "Shared libs (ldd):"
      ldd_out=$(ldd "$f" 2>&1) || ldd_out=$(ldd "$f" 2>&1)
      echo "$ldd_out"
      if echo "$ldd_out" | grep -q "not found"; then
        echo "ERROR: Missing shared libraries"
        err=1
      fi
    fi

  else
    first_line=$(head -n1 "$f" || true)
    if [[ "$first_line" =~ ^#! ]]; then
      shebang=${first_line#\#!}
      echo "Shebang:${shebang}"
      # split shebang into words
      read -r -a parts <<<"$shebang"
      interp=${parts[0]}
      cmd=""
      if [[ $(basename "$interp") == env ]]; then
        cmd=${parts[1]:-}
      else
        cmd=$interp
      fi

      if [[ -z "$cmd" ]]; then
        echo "WARNING: cannot determine interpreter from shebang"
      else
        # if interpreter is an absolute path, check it; otherwise check in PATH
        if [[ "$cmd" == /* ]]; then
          if [[ -x "$cmd" ]]; then
            echo "Interpreter exists: $cmd"
          else
            echo "ERROR: Interpreter '$cmd' not found or not executable"
            err=1
          fi
        else
          if command -v "$cmd" >/dev/null 2>&1; then
            echo "Interpreter found in PATH: $cmd"
            case "$(basename "$cmd")" in
              bash|sh|dash|ksh|zsh)
                if command -v bash >/dev/null 2>&1; then
                  if bash -n "$f" 2>/dev/null; then
                    echo "Shell syntax: OK"
                  else
                    echo "Shell syntax: ERROR"
                    err=1
                  fi
                fi
                ;;
              python|python3|python2)
                if command -v python >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1; then
                  if python -m py_compile "$f" 2>/dev/null; then
                    echo "Python: compiled OK"
                  else
                    echo "Python: compile check failed or not applicable"
                  fi
                fi
                ;;
            esac
          else
            echo "ERROR: Interpreter '$cmd' not found in PATH"
            err=1
          fi
        fi
      fi
    else
      echo "WARNING: No shebang found; file may not be a script"
    fi
  fi
done < <(find "$dir" -maxdepth 1 -type f -executable -print0)

if [[ $err -ne 0 ]]; then
  echo "\nOne or more checks failed."
fi

exit $err
