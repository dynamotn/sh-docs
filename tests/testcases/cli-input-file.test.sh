# shellcheck shell=bash
# @file tests/testcases/cli-input-file.test.sh
# @brief Testcase for a positional input file and --output.
# @description A positional argument is read instead of stdin, and --output writes the
#   document to a file rather than to stdout.

tests::put source.sh << 'SH'
#!/usr/bin/env bash
# @file strings.sh
# @brief Helpers for text manipulation.
SH

tests::put expected << 'MD'
# strings.sh

Helpers for text manipulation.

> 🧭 Source: [src/strings.sh](../src/strings.sh)
>
> Jump to: [Overview](#overview)

<a id="overview"></a>
## ✨ Overview
MD

tests::run source.sh
tests::assert_exitcode 0
tests::assert_no_diff expected stdout

tests::run --output doc.md source.sh
tests::assert_exitcode 0
tests::assert_no_diff expected doc.md
[[ ! -s stdout ]] || tests::fail 'stdout should be empty when --output is given'
