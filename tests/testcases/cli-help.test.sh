# shellcheck shell=bash
# @file tests/testcases/cli-help.test.sh
# @brief Testcase for --help and -h.
# @description --help and -h describe the interface without reading any input.

tests::run --help
tests::assert_exitcode 0
tests::assert_stdout_contains 'Usage: sh-docs [OPTION]... [FILE]'
tests::assert_stdout_contains '--example-dir'

tests::run -h
tests::assert_exitcode 0
tests::assert_stdout_contains 'Usage: sh-docs [OPTION]... [FILE]'
