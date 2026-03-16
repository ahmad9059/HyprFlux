session_root "${PROJECT_DIR:-$HOME/Documents/Projects}"

if initialize_session "${SESSION_NAME:-VieroMind}"; then

  new_window "Editor"
  run_cmd "cd \"$session_root\" && nvim"

  new_window "Agents"
  run_cmd "cd \"$session_root\" && opencode"
  # split_h 50
  # split_v 50 2
  # select_pane 1
  # run_cmd "cd \"$session_root\" && opencode"
  # select_pane 2
  # run_cmd "cd \"$session_root\" && codex"
  # select_pane 3
  # run_cmd "cd \"$session_root\" && gemini"
  # select_pane 1

  new_window "LazyGit"
  run_cmd "cd \"$session_root\" && lazygit"

  new_window "Yazi"
  run_cmd "cd \"$session_root\" && yazi"

  # new_window "Music"
  # run_cmd "cd \"$session_root\" && rmpc"

  new_window "Server"
  run_cmd "cd \"$session_root\" && (pnpm install && pnpm prisma generate && pnpm run dev)"

  # tmuxifier-tmux new-window -t "$session:10" -n "Terminal"
  # run_cmd "cd \"$session_root\""
  tmuxifier-tmux new-window -t "$session:10" -n "Terminal"
  select_window 10
  run_cmd "cd \"$session_root\""
  run_cmd "clear"

  select_window "Editor"
fi

finalize_and_go_to_session
