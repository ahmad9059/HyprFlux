#!/bin/bash
# ============================================================
# lib/git.sh — Git clone helpers for HyprFlux installer
# ============================================================
# Sourced by install.sh and dotsSetup.sh. Provides:
#   - ensure_repo()      — clone if missing, skip if exists
#   - clone_with_retry() — clone with max retry limit
# ============================================================

# Guard against double-sourcing
[[ -n "${_LIB_GIT_LOADED:-}" ]] && return 0
_LIB_GIT_LOADED=1

# ====== ensure_repo ======
# Clone a repo if the target directory does not exist.
# Usage: ensure_repo "https://github.com/user/repo.git" "/path/to/dir" [--depth=1]
ensure_repo() {
  local url="$1"
  local dir="$2"
  local depth_flag="${3:-}"

  if [[ -d "$dir" ]]; then
    log_info "Folder '$(basename "$dir")' already exists at $dir. Skipping clone."
    return 0
  fi

  log_action "Cloning $(basename "$dir") into $dir..."
  local git_args=(git clone)
  [[ -n "$depth_flag" ]] && git_args+=("$depth_flag")
  git_args+=("$url" "$dir")

  if "${git_args[@]}"; then
    log_ok "Repository cloned successfully to $dir."
    return 0
  else
    log_error "Failed to clone $url into $dir."
    return 1
  fi
}

# ====== clone_with_retry ======
# Clone a repo with retry logic and a maximum attempt limit.
# Usage: clone_with_retry "https://github.com/user/repo.git" "/path/to/dir" [max_retries] [--depth=1]
clone_with_retry() {
  local url="$1"
  local dir="$2"
  local max_retries="${3:-5}"
  local depth_flag="${4:-}"
  local count=0

  while [[ $count -lt $max_retries ]]; do
    log_action "Cloning $(basename "$dir") (attempt $((count + 1))/$max_retries)..."

    local git_args=(git clone)
    [[ -n "$depth_flag" ]] && git_args+=("$depth_flag")
    git_args+=("$url" "$dir")

    if "${git_args[@]}"; then
      log_ok "Repository cloned successfully to $dir."
      return 0
    fi

    count=$((count + 1))
    if [[ $count -lt $max_retries ]]; then
      log_warn "Clone failed. Retrying in 5 seconds..."
      sleep 5
    fi
  done

  log_error "Failed to clone $url after $max_retries attempts."
  return 1
}
