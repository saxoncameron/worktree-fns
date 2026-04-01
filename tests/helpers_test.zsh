#!/usr/bin/env zsh

source "${0:A:h}/test_helper.zsh"

test_find_repo_root_from_repo_root() {
  local repoDir
  repoDir=$(gw_test_make_repo) || return 1
  builtin cd "$repoDir" || return 1
  gw_test_assert_equal "$repoDir" "$(_gw_find_repo_root)" '_gw_find_repo_root should return repo root'
}

test_find_repo_root_from_nested_worktree_dir() {
  local repoDir
  repoDir=$(gw_test_make_repo) || return 1
  builtin cd "$repoDir" || return 1
  gwa feature >/dev/null 2>&1 || return 1
  mkdir -p "$repoDir/.worktrees/feature/nested/deeper" || return 1
  builtin cd "$repoDir/.worktrees/feature/nested/deeper" || return 1
  gw_test_assert_equal "$repoDir" "$(_gw_find_repo_root)" '_gw_find_repo_root should climb out of worktrees'
}

test_resolve_worktree_dir_supports_name_relative_absolute_and_flags() {
  local repoDir worktreeDir
  repoDir=$(gw_test_make_repo) || return 1
  builtin cd "$repoDir" || return 1
  gwa feature >/dev/null 2>&1 || return 1
  worktreeDir="$repoDir/.worktrees/feature"
  builtin cd "$repoDir" || return 1

  gw_test_assert_equal "$worktreeDir" "$(_gw_resolve_worktree_dir "$repoDir" feature)" 'worktree names should resolve'
  gw_test_assert_equal "$worktreeDir" "$(_gw_resolve_worktree_dir "$repoDir" "./.worktrees/feature")" 'relative worktree paths should resolve'
  gw_test_assert_equal "$worktreeDir" "$(_gw_resolve_worktree_dir "$repoDir" "$worktreeDir")" 'absolute worktree paths should resolve'
  gw_test_assert_equal "$worktreeDir" "$(_gw_resolve_worktree_dir "$repoDir" --force missing feature)" 'flags should be ignored and last real argument used'
}

test_worktree_dirs_filters_unmanaged_directories() {
  local repoDir output
  repoDir=$(gw_test_make_repo) || return 1
  builtin cd "$repoDir" || return 1
  gwa feature >/dev/null 2>&1 || return 1
  mkdir -p "$repoDir/.worktrees/not-a-worktree" || return 1

  output=$(_gw_worktree_dirs "$repoDir")
  gw_test_assert_contains "$output" "$repoDir/.worktrees/feature" 'managed worktrees should be listed'
  gw_test_assert_not_contains "$output" "$repoDir/.worktrees/not-a-worktree" 'unmanaged directories should be filtered out'
}

test_copy_local_overlay_files_fills_missing_files_only() {
  local repoDir targetDir
  repoDir=$(gw_test_make_repo) || return 1
  targetDir=$(mktemp -d "${TMPDIR:-/tmp}/worktree-overlay.XXXXXX") || return 1
  GW_TEST_TMP_PATHS+=("$targetDir")

  mkdir -p "$targetDir/config" || return 1
  print -r -- 'KEEP=1' > "$targetDir/.env"

  _gw_copy_local_overlay_files "$repoDir" "$targetDir" || return 1

  gw_test_assert_equal 'KEEP=1' "$(<"$targetDir/.env")" 'overlay copy should not overwrite existing files'
  gw_test_assert_equal '*.cache' "$(<"$targetDir/config/.gitignore")" 'overlay copy should copy nested gitignore files'
}

gw_test_run '_gw_find_repo_root resolves repo root' test_find_repo_root_from_repo_root
gw_test_run '_gw_find_repo_root climbs out of worktrees' test_find_repo_root_from_nested_worktree_dir
gw_test_run '_gw_resolve_worktree_dir handles supported arguments' test_resolve_worktree_dir_supports_name_relative_absolute_and_flags
gw_test_run '_gw_worktree_dirs filters invalid directories' test_worktree_dirs_filters_unmanaged_directories
gw_test_run '_gw_copy_local_overlay_files copies overlays conservatively' test_copy_local_overlay_files_fills_missing_files_only
