#!/usr/bin/env zsh

source "${0:A:h}/test_helper.zsh"

test_gwa_creates_worktree_and_copies_overlays() {
  local repoDir worktreeDir
  repoDir=$(gw_test_make_repo) || return 1
  builtin cd "$repoDir" || return 1
  gw_test_capture gwa feature
  gw_test_assert_status 0 "$GW_TEST_CAPTURE_STATUS" 'gwa should succeed'
  worktreeDir="$repoDir/.worktrees/feature"

  [[ -d "$worktreeDir" ]] || return $(gw_test_record_failure 'gwa should create the requested worktree directory')
  gw_test_assert_equal "$worktreeDir" "$PWD" 'gwa should cd into the new worktree'
  gw_test_assert_equal 'feature' "$(gw_test_worktree_branch "$worktreeDir")" 'gwa should create a matching branch'
  gw_test_assert_equal 'ENV=development' "$(<"$worktreeDir/.env")" 'gwa should copy .env into new worktrees'
  gw_test_assert_equal '*.cache' "$(<"$worktreeDir/config/.gitignore")" 'gwa should copy nested gitignore files into new worktrees'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" '🌴' 'gwa should log with the project emoji'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" 'Creating worktree' 'gwa should log creation'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" 'Entered worktree' 'gwa should log success'
}

test_gwcd_gwp_and_gwt_change_directories() {
  local repoDir worktreeDir
  repoDir=$(gw_test_make_repo) || return 1
  builtin cd "$repoDir" || return 1
  gwa feature >/dev/null 2>&1 || return 1
  worktreeDir="$repoDir/.worktrees/feature"

  builtin cd "$repoDir" || return 1
  gw_test_capture gwcd feature
  gw_test_assert_status 0 "$GW_TEST_CAPTURE_STATUS" 'gwcd should succeed'
  gw_test_assert_equal "$worktreeDir" "$PWD" 'gwcd should jump into named worktrees'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" '🌴' 'gwcd should log with the project emoji'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" 'Entered worktree' 'gwcd should log success'

  mkdir -p "$worktreeDir/src/nested" || return 1
  builtin cd "$worktreeDir/src/nested" || return 1
  gw_test_capture gwt
  gw_test_assert_status 0 "$GW_TEST_CAPTURE_STATUS" 'gwt should succeed'
  gw_test_assert_equal "$worktreeDir" "$PWD" 'gwt should jump to the current worktree root'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" 'Returned to worktree root' 'gwt should log navigation'

  builtin cd "$worktreeDir/src/nested" || return 1
  gw_test_capture gwp
  gw_test_assert_status 0 "$GW_TEST_CAPTURE_STATUS" 'gwp should succeed'
  gw_test_assert_equal "$repoDir" "$PWD" 'gwp should jump to the owning repo root'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" 'Returned to repo root' 'gwp should log navigation'
}

test_gwt_logs_info_when_not_inside_managed_worktree() {
  local emptyDir repoDir
  emptyDir=$(mktemp -d "${TMPDIR:-/tmp}/worktree-fns-empty.XXXXXX") || return 1
  emptyDir=${emptyDir:A}
  GW_TEST_TMP_PATHS+=("$emptyDir")

  builtin cd "$emptyDir" || return 1
  gw_test_capture gwt
  gw_test_assert_status 0 "$GW_TEST_CAPTURE_STATUS" 'gwt should succeed outside a worktree'
  gw_test_assert_equal "$emptyDir" "$PWD" 'gwt should leave the current directory unchanged outside a worktree'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" '🌴 [info]' 'gwt should log the no-worktree case as info'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" 'No worktree root to return to.' 'gwt should explain the no-worktree case'

  repoDir=$(gw_test_make_repo) || return 1
  builtin cd "$repoDir" || return 1
  gw_test_capture gwt
  gw_test_assert_status 0 "$GW_TEST_CAPTURE_STATUS" 'gwt should also succeed at the repo root'
  gw_test_assert_equal "$repoDir" "$PWD" 'gwt should leave the repo root unchanged'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" '🌴 [info]' 'gwt should log the repo-root case as info'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" 'No worktree root to return to.' 'gwt should explain the repo-root case'
}

test_gwls_reports_empty_and_populated_states() {
  local repoDir
  repoDir=$(gw_test_make_repo) || return 1
  builtin cd "$repoDir" || return 1

  gw_test_capture gwls
  gw_test_assert_status 0 "$GW_TEST_CAPTURE_STATUS" 'gwls should succeed with no worktrees'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" 'No worktrees found.' 'gwls should report empty state'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" '🌴' 'gwls should use the project emoji'

  gwa feature >/dev/null 2>&1 || return 1
  gw_test_capture gwls
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" 'Available worktrees:' 'gwls should report populated state'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" 'feature' 'gwls should include worktree names'
}

test_gwdiff_reports_usage_clean_and_dirty_states() {
  local GW_LOG_STYLE='plain' repoDir worktreeDir
  repoDir=$(gw_test_make_repo) || return 1
  builtin cd "$repoDir" || return 1

  gw_test_capture gwdiff
  gw_test_assert_status 1 "$GW_TEST_CAPTURE_STATUS" 'gwdiff without args should fail'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDERR" 'Usage: gwdiff <worktree>' 'gwdiff should print usage on missing args'

  gwa feature >/dev/null 2>&1 || return 1
  worktreeDir="$repoDir/.worktrees/feature"

  gw_test_capture gwdiff feature
  gw_test_assert_status 0 "$GW_TEST_CAPTURE_STATUS" 'gwdiff should succeed on clean worktrees'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" '🌴' 'gwdiff should use the project emoji'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" 'Inspecting worktree' 'gwdiff should log what it is inspecting'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" 'Worktree has no pending changes:' 'gwdiff should report clean worktrees'
  gw_test_assert_not_contains "$GW_TEST_CAPTURE_STDOUT" $'\n\n🌴 [success] Worktree has no pending changes:' 'clean gwdiff should not insert a blank line before the summary'

  print -r -- 'dirty change' >> "$worktreeDir/base.txt"
  gw_test_capture gwdiff feature
  gw_test_assert_status 0 "$GW_TEST_CAPTURE_STATUS" 'gwdiff should still succeed on dirty worktrees'
  gw_test_assert_not_contains "$GW_TEST_CAPTURE_STDOUT" 'Worktree has pending changes:' 'gwdiff should skip the redundant dirty-worktree heading'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" '🌴 [info] Unstaged changes:' 'gwdiff should label unstaged summaries as info'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" 'Unstaged changes:' 'gwdiff should show unstaged summaries'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" $'\n\n🌴 [info] Unstaged changes:' 'dirty gwdiff should insert a single blank line before unstaged changes'
  gw_test_assert_not_contains "$GW_TEST_CAPTURE_STDOUT" $'\n\n\n🌴 [info] Unmerged commits:' 'dirty gwdiff should not insert extra blank lines before unmerged commits'

  builtin cd "$worktreeDir" || return 1
  gw_test_capture gwdiff
  gw_test_assert_status 0 "$GW_TEST_CAPTURE_STATUS" 'gwdiff without args should use the current worktree when inside one'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" 'Inspecting worktree' 'gwdiff without args should inspect the current worktree'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" 'feature' 'gwdiff without args should target the current worktree name'
}

test_gwh_preserves_branch_and_rejects_dirty_worktrees() {
  local repoDir worktreeDir branchStillExists
  repoDir=$(gw_test_make_repo) || return 1
  builtin cd "$repoDir" || return 1

  gwa feature >/dev/null 2>&1 || return 1
  worktreeDir="$repoDir/.worktrees/feature"
  print -r -- 'dirty change' >> "$worktreeDir/base.txt"

  gw_test_capture gwh feature
  gw_test_assert_status 1 "$GW_TEST_CAPTURE_STATUS" 'gwh should reject dirty worktrees'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT$GW_TEST_CAPTURE_STDERR" 'error: worktree has uncommitted changes' 'gwh should explain dirty worktree failures'

  repoDir=$(gw_test_make_repo) || return 1
  /bin/rm -f "$repoDir/.env" "$repoDir/config/.gitignore"
  builtin cd "$repoDir" || return 1
  gwa feature >/dev/null 2>&1 || return 1
  worktreeDir="$repoDir/.worktrees/feature"

  gw_test_capture gwh feature
  gw_test_assert_status 0 "$GW_TEST_CAPTURE_STATUS" 'gwh should succeed on clean worktrees'
  [[ ! -d "$worktreeDir" ]] || return $(gw_test_record_failure 'gwh should remove the worktree directory')

  branchStillExists=$(git -C "$repoDir" branch --list feature)
  gw_test_assert_contains "$branchStillExists" 'feature' 'gwh should preserve the branch'
}

gw_test_run 'gwa creates worktrees and copies overlays' test_gwa_creates_worktree_and_copies_overlays
gw_test_run 'gwcd, gwp, and gwt change directories correctly' test_gwcd_gwp_and_gwt_change_directories
gw_test_run 'gwt logs info when not inside managed worktree' test_gwt_logs_info_when_not_inside_managed_worktree
gw_test_run 'gwls reports empty and populated states' test_gwls_reports_empty_and_populated_states
gw_test_run 'gwdiff reports usage, clean, and dirty states' test_gwdiff_reports_usage_clean_and_dirty_states
gw_test_run 'gwh preserves branches and rejects dirty worktrees' test_gwh_preserves_branch_and_rejects_dirty_worktrees
