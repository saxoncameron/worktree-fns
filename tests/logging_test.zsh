#!/usr/bin/env zsh

source "${0:A:h}/test_helper.zsh"

test_log_outputs_emoji_by_default() {
  gw_test_capture _gw_log success 'Styled log message'
  gw_test_assert_status 0 "$GW_TEST_CAPTURE_STATUS" '_gw_log should succeed with styled output'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" '🌱' '_gw_log should include the project emoji by default'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" '[success]' '_gw_log should include the log label'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" 'Styled log message' '_gw_log should include the message text'
}

test_log_supports_plain_mode() {
  local previousStyle
  previousStyle=${GW_LOG_STYLE:-}
  GW_LOG_STYLE='plain'
  gw_test_capture _gw_log error 'Plain log message'
  GW_LOG_STYLE=$previousStyle

  gw_test_assert_status 0 "$GW_TEST_CAPTURE_STATUS" '_gw_log should succeed in plain mode'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" '🌱 [error] Plain log message' '_gw_log should emit the project emoji and plain labels when requested'
}

test_log_renders_step_as_ellipsis() {
  local previousStyle
  previousStyle=${GW_LOG_STYLE:-}
  GW_LOG_STYLE='plain'
  gw_test_capture _gw_log step 'Working on something'
  GW_LOG_STYLE=$previousStyle

  gw_test_assert_status 0 "$GW_TEST_CAPTURE_STATUS" '_gw_log should succeed for step messages'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" '🌱 [...] Working on something' '_gw_log should render step labels as ellipsis'
  gw_test_assert_not_contains "$GW_TEST_CAPTURE_STDOUT" '[step]' '_gw_log should not render the literal step label'
}

test_gwls_uses_dash_worktree_markers() {
  local repoDir
  repoDir=$(gw_test_make_repo) || return 1
  builtin cd "$repoDir" || return 1
  gwa feature >/dev/null 2>&1 || return 1

  gw_test_capture gwls
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" '🌱 [list]' 'gwls should keep the project emoji in the list heading'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" '  - ' 'gwls should render worktree entries with dash bullets'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" 'Available worktrees:' 'gwls should keep the list heading text'
}

test_gwr_logs_force_removal_with_project_prefix() {
  local repoDir worktreeDir
  repoDir=$(gw_test_make_repo) || return 1
  builtin cd "$repoDir" || return 1
  gwa feature >/dev/null 2>&1 || return 1
  worktreeDir="$repoDir/.worktrees/feature"
  print -r -- 'dirty change' >> "$worktreeDir/base.txt"
  builtin cd "$repoDir" || return 1

  gw_test_capture gwrf feature
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" '🌱' 'gwrf should use the project emoji'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" 'Force-removing worktree' 'gwrf should log force deletion explicitly'
}

gw_test_run '_gw_log emits emoji by default' test_log_outputs_emoji_by_default
gw_test_run '_gw_log supports plain mode' test_log_supports_plain_mode
gw_test_run '_gw_log renders step as ellipsis' test_log_renders_step_as_ellipsis
gw_test_run 'gwls uses dash worktree markers' test_gwls_uses_dash_worktree_markers
gw_test_run 'gwrf logs force removal with the project emoji' test_gwr_logs_force_removal_with_project_prefix
