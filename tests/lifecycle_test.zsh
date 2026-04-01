#!/usr/bin/env zsh

source "${0:A:h}/test_helper.zsh"

test_gwd_removes_named_worktree_and_matching_branch() {
  local repoDir worktreeDir branches
  repoDir=$(gw_test_make_repo) || return 1
  builtin cd "$repoDir" || return 1
  gwa feature >/dev/null 2>&1 || return 1
  worktreeDir="$repoDir/.worktrees/feature"
  builtin cd "$repoDir" || return 1

  gw_test_capture gwd feature
  gw_test_assert_status 0 "$GW_TEST_CAPTURE_STATUS" 'gwd should remove worktrees by bare name'
  [[ ! -d "$worktreeDir" ]] || return $(gw_test_record_failure 'gwd should remove the target worktree directory')
  branches=$(git -C "$repoDir" branch --list feature)
  [[ -z "$branches" ]] || return $(gw_test_record_failure 'gwd should delete same-named branches')
}

test_gwd_preserves_differently_named_branch() {
  local repoDir worktreeDir branches
  repoDir=$(gw_test_make_repo) || return 1
  git -C "$repoDir" branch keep-branch >/dev/null 2>&1 || return 1
  builtin cd "$repoDir" || return 1
  gwa sandbox keep-branch >/dev/null 2>&1 || return 1
  worktreeDir="$repoDir/.worktrees/sandbox"
  builtin cd "$repoDir" || return 1

  gw_test_capture gwd sandbox
  gw_test_assert_status 0 "$GW_TEST_CAPTURE_STATUS" 'gwd should remove worktrees with non-matching branches'
  [[ ! -d "$worktreeDir" ]] || return $(gw_test_record_failure 'gwd should remove the sandbox worktree directory')
  branches=$(git -C "$repoDir" branch --list keep-branch)
  gw_test_assert_contains "$branches" 'keep-branch' 'gwd should preserve differently named branches'
}

test_gwd_blocks_unmerged_commits_and_gwdf_forces_cleanup() {
  local repoDir worktreeDir
  repoDir=$(gw_test_make_repo) || return 1
  builtin cd "$repoDir" || return 1
  gwa feature >/dev/null 2>&1 || return 1
  worktreeDir="$repoDir/.worktrees/feature"
  gw_test_append_commit "$worktreeDir" 'base.txt' 'feature work' 'feature change' || return 1
  builtin cd "$repoDir" || return 1

  gw_test_capture gwd feature
  gw_test_assert_status 1 "$GW_TEST_CAPTURE_STATUS" 'gwd should block worktrees with unmerged commits'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT$GW_TEST_CAPTURE_STDERR" 'error: worktree has unmerged commits' 'gwd should explain unmerged commit failures'
  [[ -d "$worktreeDir" ]] || return $(gw_test_record_failure 'gwd should leave blocked worktrees in place')

  gw_test_capture gwdf feature
  gw_test_assert_status 0 "$GW_TEST_CAPTURE_STATUS" 'gwdf should force-remove worktrees with unmerged commits'
  [[ ! -d "$worktreeDir" ]] || return $(gw_test_record_failure 'gwdf should remove the blocked worktree directory')
}

test_gwd_returns_to_repo_root_when_removing_current_worktree() {
  local repoDir worktreeDir
  repoDir=$(gw_test_make_repo) || return 1
  builtin cd "$repoDir" || return 1
  gwa feature >/dev/null 2>&1 || return 1
  worktreeDir="$repoDir/.worktrees/feature"
  mkdir -p "$worktreeDir/src/nested" || return 1
  builtin cd "$worktreeDir/src/nested" || return 1

  gw_test_capture gwd feature
  gw_test_assert_status 0 "$GW_TEST_CAPTURE_STATUS" 'gwd should succeed from inside the target worktree'
  gw_test_assert_equal "$repoDir" "$PWD" 'gwd should return to the repo root after removing the active worktree'
}

test_gwm_merges_and_cleans_up_worktree() {
  local repoDir worktreeDir mergedContents branches
  repoDir=$(gw_test_make_repo) || return 1
  builtin cd "$repoDir" || return 1
  gwa feature >/dev/null 2>&1 || return 1
  worktreeDir="$repoDir/.worktrees/feature"
  gw_test_append_commit "$worktreeDir" 'base.txt' 'merged feature line' 'feature merge' || return 1
  builtin cd "$repoDir" || return 1

  gw_test_capture gwm feature
  gw_test_assert_status 0 "$GW_TEST_CAPTURE_STATUS" 'gwm should merge clean worktrees'
  mergedContents=$(<"$repoDir/base.txt")
  gw_test_assert_contains "$mergedContents" 'merged feature line' 'gwm should merge worktree commits into the repo root'
  [[ ! -d "$worktreeDir" ]] || return $(gw_test_record_failure 'gwm should remove the merged worktree')
  branches=$(git -C "$repoDir" branch --list feature)
  [[ -z "$branches" ]] || return $(gw_test_record_failure 'gwm should delete the merged branch via gwd')
}

test_gwm_aborts_conflicts_and_keeps_worktree() {
  local repoDir worktreeDir mergeHead
  repoDir=$(gw_test_make_repo) || return 1
  builtin cd "$repoDir" || return 1
  gwa feature >/dev/null 2>&1 || return 1
  worktreeDir="$repoDir/.worktrees/feature"

  print -r -- 'root side' > "$repoDir/base.txt"
  git -C "$repoDir" add base.txt || return 1
  git -C "$repoDir" commit -q -m 'root change' || return 1

  print -r -- 'feature side' > "$worktreeDir/base.txt"
  git -C "$worktreeDir" add base.txt || return 1
  git -C "$worktreeDir" commit -q -m 'feature change' || return 1

  builtin cd "$repoDir" || return 1
  gw_test_capture gwm feature
  gw_test_assert_status 1 "$GW_TEST_CAPTURE_STATUS" 'gwm should fail on merge conflicts'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT$GW_TEST_CAPTURE_STDERR" 'error: merge conflict' 'gwm should explain merge conflicts'

  mergeHead=$(git -C "$repoDir" rev-parse --verify MERGE_HEAD 2>/dev/null)
  [[ -z "$mergeHead" ]] || return $(gw_test_record_failure 'gwm should abort the merge after a conflict')
  [[ -d "$worktreeDir" ]] || return $(gw_test_record_failure 'gwm should keep the conflicting worktree in place')
}

gw_test_run 'gwd removes named worktrees and same-named branches' test_gwd_removes_named_worktree_and_matching_branch
gw_test_run 'gwd preserves differently named branches' test_gwd_preserves_differently_named_branch
gw_test_run 'gwd blocks unmerged commits and gwdf forces cleanup' test_gwd_blocks_unmerged_commits_and_gwdf_forces_cleanup
gw_test_run 'gwd returns to repo root when removing current worktree' test_gwd_returns_to_repo_root_when_removing_current_worktree
gw_test_run 'gwm merges clean worktrees and cleans up' test_gwm_merges_and_cleans_up_worktree
gw_test_run 'gwm aborts conflicts and keeps the worktree' test_gwm_aborts_conflicts_and_keeps_worktree
