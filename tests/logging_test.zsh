#!/usr/bin/env zsh

source "${0:A:h}/test_helper.zsh"

test_log_outputs_emoji_by_default() {
  gw_test_capture _gw_log success 'Styled log message'
  gw_test_assert_status 0 "$GW_TEST_CAPTURE_STATUS" '_gw_log should succeed with styled output'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" '✅' '_gw_log should include emojis by default'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" 'Styled log message' '_gw_log should include the message text'
}

test_log_supports_plain_mode() {
  local previousStyle
  previousStyle=${GW_LOG_STYLE:-}
  GW_LOG_STYLE='plain'
  gw_test_capture _gw_log error 'Plain log message'
  GW_LOG_STYLE=$previousStyle

  gw_test_assert_status 0 "$GW_TEST_CAPTURE_STATUS" '_gw_log should succeed in plain mode'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" '[error] Plain log message' '_gw_log should emit plain labels when requested'
  gw_test_assert_not_contains "$GW_TEST_CAPTURE_STDOUT" '❌' '_gw_log plain mode should suppress emoji'
}

test_gwls_uses_visual_worktree_markers() {
  local repoDir
  repoDir=$(gw_test_make_repo) || return 1
  builtin cd "$repoDir" || return 1
  gwa feature >/dev/null 2>&1 || return 1

  gw_test_capture gwls
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" '🌿' 'gwls should render worktree markers with emoji'
  gw_test_assert_contains "$GW_TEST_CAPTURE_STDOUT" 'Available worktrees:' 'gwls should keep the list heading text'
}

gw_test_run '_gw_log emits emoji by default' test_log_outputs_emoji_by_default
gw_test_run '_gw_log supports plain mode' test_log_supports_plain_mode
gw_test_run 'gwls uses visual worktree markers' test_gwls_uses_visual_worktree_markers
