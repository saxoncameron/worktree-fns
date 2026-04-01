#!/usr/bin/env zsh

source "${0:A:h}/test_helper.zsh"

typeset -ga GW_TEST_COMPLETION_RESULTS=()
typeset -gi GW_TEST_DESCRIBE_CALLS=0

_describe() {
  GW_TEST_COMPLETION_RESULTS=("${(@P)2}")
  (( ++GW_TEST_DESCRIBE_CALLS ))
}

test_completion_lists_only_managed_worktree_names() {
  local repoDir
  repoDir=$(gw_test_make_repo) || return 1
  builtin cd "$repoDir" || return 1
  gwa feature >/dev/null 2>&1 || return 1
  mkdir -p "$repoDir/.worktrees/not-a-worktree" || return 1

  GW_TEST_COMPLETION_RESULTS=()
  GW_TEST_DESCRIBE_CALLS=0
  words=(gwd '')
  CURRENT=2
  _gw_worktree_names || return 1

  gw_test_assert_contains "${(j: :)GW_TEST_COMPLETION_RESULTS}" 'feature' 'completion should include managed worktrees'
  gw_test_assert_not_contains "${(j: :)GW_TEST_COMPLETION_RESULTS}" 'not-a-worktree' 'completion should skip unmanaged directories'
}

test_completion_stops_after_first_nonflag_argument() {
  local repoDir
  repoDir=$(gw_test_make_repo) || return 1
  builtin cd "$repoDir" || return 1
  gwa feature >/dev/null 2>&1 || return 1

  GW_TEST_COMPLETION_RESULTS=()
  GW_TEST_DESCRIBE_CALLS=0
  words=(gwd feature '')
  CURRENT=3
  _gw_worktree_names || return 1

  gw_test_assert_equal '0' "$GW_TEST_DESCRIBE_CALLS" 'completion should stop after the first non-flag argument'
}

gw_test_run 'completion lists only managed worktree names' test_completion_lists_only_managed_worktree_names
gw_test_run 'completion stops after the first non-flag argument' test_completion_stops_after_first_nonflag_argument
