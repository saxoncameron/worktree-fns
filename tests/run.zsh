#!/usr/bin/env zsh

setopt no_aliases

local testFile testRoot
testRoot=${0:A:h}

source "$testRoot/test_helper.zsh"

for testFile in "$testRoot"/*_test.zsh(.N); do
  [[ "$testFile" == "$testRoot/test_helper.zsh" ]] && continue
  source "$testFile" || exit 1
done

gw_test_finish
