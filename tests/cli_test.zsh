#!/usr/bin/env zsh

source "${0:A:h}/test_helper.zsh"

test_cli_reports_paths_for_navigation_commands() {
  local repoDir worktreeDir repoRootFromCli worktreeRootFromCli
  repoDir=$(gw_test_make_repo) || return 1
  builtin cd "$repoDir" || return 1

  gw_test_capture "$GW_TEST_ROOT/bin/worktree-fns" add feature
  gw_test_assert_status 0 "$GW_TEST_CAPTURE_STATUS" 'worktree-fns add should succeed'
  worktreeDir=$GW_TEST_CAPTURE_STDOUT
  [[ -d "$worktreeDir" ]] || return $(gw_test_record_failure 'worktree-fns add should create the worktree directory')
  gw_test_assert_equal "$repoDir" "$PWD" 'worktree-fns add should not change the caller shell directory'

  gw_test_capture "$GW_TEST_ROOT/bin/worktree-fns" cd feature
  gw_test_assert_equal "$worktreeDir" "$GW_TEST_CAPTURE_STDOUT" 'worktree-fns cd should print the target worktree path'

  builtin cd "$worktreeDir" || return 1
  gw_test_capture "$GW_TEST_ROOT/bin/worktree-fns" project-root
  repoRootFromCli=$GW_TEST_CAPTURE_STDOUT
  gw_test_assert_equal "$repoDir" "$repoRootFromCli" 'worktree-fns project-root should print the owning repo root'

  mkdir -p "$worktreeDir/src/nested" || return 1
  builtin cd "$worktreeDir/src/nested" || return 1
  gw_test_capture "$GW_TEST_ROOT/bin/worktree-fns" worktree-root
  worktreeRootFromCli=$GW_TEST_CAPTURE_STDOUT
  gw_test_assert_equal "$worktreeDir" "$worktreeRootFromCli" 'worktree-fns worktree-root should print the current worktree root'
}

test_cli_init_and_install_expose_sourceable_entrypoint() {
  local initLine prefix
  prefix=$(mktemp -d "${TMPDIR:-/tmp}/worktree-install.XXXXXX") || return 1
  prefix=${prefix:A}
  GW_TEST_TMP_PATHS+=("$prefix")

  gw_test_capture "$GW_TEST_ROOT/bin/worktree-fns" init zsh
  gw_test_assert_status 0 "$GW_TEST_CAPTURE_STATUS" 'worktree-fns init zsh should succeed'
  initLine=$GW_TEST_CAPTURE_STDOUT
  gw_test_assert_contains "$initLine" 'source' 'worktree-fns init zsh should output a source command'
  gw_test_assert_contains "$initLine" "$GW_TEST_ROOT/worktree-fns.zsh" 'worktree-fns init zsh should point at the repo entrypoint'

  make install PREFIX="$prefix" >/dev/null 2>&1 || return 1
  [[ -x "$prefix/bin/worktree-fns" ]] || return $(gw_test_record_failure 'make install should install the standalone binary')
  [[ -f "$prefix/lib/worktree-fns/worktree-fns.zsh" ]] || return $(gw_test_record_failure 'make install should install the zsh entrypoint')

  source "$prefix/lib/worktree-fns/worktree-fns.zsh" || return 1
  whence -w gwls | grep -q 'function' || return $(gw_test_record_failure 'installed entrypoint should expose public shell functions')
}

gw_test_run 'worktree-fns CLI prints navigation paths' test_cli_reports_paths_for_navigation_commands
gw_test_run 'worktree-fns init and install expose sourceable entrypoints' test_cli_init_and_install_expose_sourceable_entrypoint
