# Entrypoint for the worktree helper suite.
#
# This file is the only thing ~/.zshrc needs to source. It adds the repo's
# function and completion directories to zsh's autoload path, then registers
# the public commands and their shared completion function.

typeset -gU fpath
typeset -g _worktree_fns_root=${${(%):-%N}:A:h}
fpath=(
  $_worktree_fns_root/functions
  $_worktree_fns_root/completions
  $fpath
)

# Autoload the public commands.
autoload -Uz gwa gwcd gwd gwdf gwdiff gwls gwp gwr

# Autoload shared helpers so command files can call them on demand.
autoload -Uz \
  _gw_colorize_status_output \
  _gw_copy_local_overlay_files \
  _gw_find_repo_root \
  _gw_print_worktree_diff \
  _gw_resolve_worktree_dir \
  _gw_spinner \
  _gw_worktree_names

# Register one completion function for every command that expects a worktree
# name. The guard keeps sourcing safe even if compinit has not run yet.
(( $+functions[compdef] )) && compdef _gw_worktree_names gwcd gwd gwdf gwdiff
