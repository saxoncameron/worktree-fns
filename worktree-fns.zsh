# Entrypoint for the worktree helper suite.
#
# This file is the only thing ~/.zshrc needs to source. It adds the repo's
# function and completion directories to zsh's autoload path, then registers
# the public commands and their shared completion function.

typeset -gU fpath
typeset -g _worktree_fns_root=${${(%):-%N}:A:h}
typeset -g _worktree_fns_bin=$_worktree_fns_root/bin/worktree-fns
fpath=(
  $_worktree_fns_root/functions
  $_worktree_fns_root/completions
  $fpath
)

# Autoload the public commands.
autoload -Uz gwa gwcd gwd gwdf gwdiff gwh gwls gwm gwp gwr

# Autoload shared helpers so command files can call them on demand.
autoload -Uz \
  _gw_add_worktree \
  _gw_cli_dispatch \
  _gw_colorize_status_output \
  _gw_copy_local_overlay_files \
  _gw_find_repo_root \
  _gw_log \
  _gw_overlay_relpaths \
  _gw_print_worktree_diff \
  _gw_prune_clean_overlay_files \
  _gw_repo_root_path \
  _gw_resolve_worktree_dir \
  _gw_selected_worktree_path \
  _gw_usage \
  _gw_worktree_root_path \
  _gw_worktree_dirs \
  _gw_worktree_names

# Register one completion function for every command that expects a worktree
# name. The guard keeps sourcing safe even if compinit has not run yet.
(( $+functions[compdef] )) && compdef _gw_worktree_names gwcd gwd gwdf gwdiff gwh gwm

return 0
