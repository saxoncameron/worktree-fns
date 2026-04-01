#!/usr/bin/env zsh

[[ -n ${GW_TEST_HELPER_LOADED:-} ]] && return 0
typeset -g GW_TEST_HELPER_LOADED=1

setopt no_aliases

typeset -g GW_TEST_ROOT=${${(%):-%N}:A:h:h}
typeset -ga GW_TEST_FAILURES=()
typeset -ga GW_TEST_TMP_PATHS=()
typeset -gi GW_TEST_COUNT=0
typeset -gi GW_TEST_FAILURE_COUNT=0
typeset -g GW_TEST_CAPTURE_STDOUT=''
typeset -g GW_TEST_CAPTURE_STDERR=''
typeset -gi GW_TEST_CAPTURE_STATUS=0

source "$GW_TEST_ROOT/worktree-fns.zsh"

gw_test_record_failure() {
  GW_TEST_FAILURES+=("$1")
  (( ++GW_TEST_FAILURE_COUNT ))
  print -u2 -r -- "not ok - $1"
  return 1
}

gw_test_record_success() {
  print -r -- "ok - $1"
}

gw_test_assert_equal() {
  local expected actual message
  expected=$1
  actual=$2
  message=$3

  [[ "$actual" == "$expected" ]] && return 0
  gw_test_record_failure "$message (expected: $expected, actual: $actual)"
}

gw_test_assert_contains() {
  local haystack needle message
  haystack=$1
  needle=$2
  message=$3

  [[ "$haystack" == *"$needle"* ]] && return 0
  gw_test_record_failure "$message (missing: $needle)"
}

gw_test_assert_not_contains() {
  local haystack needle message
  haystack=$1
  needle=$2
  message=$3

  [[ "$haystack" != *"$needle"* ]] && return 0
  gw_test_record_failure "$message (unexpected: $needle)"
}

gw_test_assert_status() {
  local expected actual message
  expected=$1
  actual=$2
  message=$3

  (( actual == expected )) && return 0
  gw_test_record_failure "$message (expected: $expected, actual: $actual)"
}

gw_test_reset_capture() {
  GW_TEST_CAPTURE_STDOUT=''
  GW_TEST_CAPTURE_STDERR=''
  GW_TEST_CAPTURE_STATUS=0
}

gw_test_capture() {
  local stdoutFile stderrFile
  stdoutFile=$(mktemp "${TMPDIR:-/tmp}/gw-test.stdout.XXXXXX") || return 1
  stderrFile=$(mktemp "${TMPDIR:-/tmp}/gw-test.stderr.XXXXXX") || {
    /bin/rm -f "$stdoutFile"
    return 1
  }

  GW_TEST_TMP_PATHS+=("$stdoutFile" "$stderrFile")
  gw_test_reset_capture

  "$@" >"$stdoutFile" 2>"$stderrFile"
  GW_TEST_CAPTURE_STATUS=$?
  GW_TEST_CAPTURE_STDOUT=$(<"$stdoutFile")
  GW_TEST_CAPTURE_STDERR=$(<"$stderrFile")
  /bin/rm -f "$stdoutFile" "$stderrFile"
}

gw_test_make_repo() {
  local repoDir
  repoDir=$(mktemp -d "${TMPDIR:-/tmp}/worktree-fns-test.XXXXXX") || return 1
  repoDir=${repoDir:A}
  GW_TEST_TMP_PATHS+=("$repoDir")

  git init -q -b main "$repoDir" || return 1
  git -C "$repoDir" config user.name 'Worktree Tests' || return 1
  git -C "$repoDir" config user.email 'worktree-tests@example.com' || return 1

  mkdir -p "$repoDir/.worktrees" "$repoDir/config" || return 1
  print -r -- 'tracked root file' > "$repoDir/base.txt"
  print -r -- 'ENV=development' > "$repoDir/.env"
  print -r -- '*.cache' > "$repoDir/config/.gitignore"

  git -C "$repoDir" add base.txt || return 1
  git -C "$repoDir" commit -q -m 'init' || return 1
  print -r -- "${repoDir:A}"
}

gw_test_append_commit() {
  local repoDir filePath content message
  repoDir=$1
  filePath=$2
  content=$3
  message=$4

  print -r -- "$content" >> "$repoDir/$filePath"
  git -C "$repoDir" add "$filePath" || return 1
  git -C "$repoDir" commit -q -m "$message" || return 1
}

gw_test_worktree_branch() {
  git -C "$1" symbolic-ref --quiet --short HEAD 2>/dev/null
}

gw_test_cleanup_paths() {
  local path
  for path in "${GW_TEST_TMP_PATHS[@]}"; do
    [[ -e "$path" ]] && /bin/rm -rf "$path"
  done
}

gw_test_finish() {
  gw_test_cleanup_paths

  if (( GW_TEST_FAILURE_COUNT )); then
    print -u2 -r -- "${GW_TEST_FAILURE_COUNT}/${GW_TEST_COUNT} tests failed"
    return 1
  fi

  print -r -- "${GW_TEST_COUNT} tests passed"
}

gw_test_run() {
  local name fn failedBefore rc
  name=$1
  fn=$2
  failedBefore=$GW_TEST_FAILURE_COUNT

  builtin cd "$GW_TEST_ROOT" || return 1
  gw_test_reset_capture

  "$fn"
  rc=$?

  (( ++GW_TEST_COUNT ))

  if (( rc == 0 && GW_TEST_FAILURE_COUNT == failedBefore )); then
    gw_test_record_success "$name"
    return 0
  fi

  if (( GW_TEST_FAILURE_COUNT == failedBefore )); then
    gw_test_record_failure "$name (returned: $rc)"
    return 1
  fi

  return 1
}
