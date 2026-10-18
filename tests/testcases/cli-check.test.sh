# shellcheck shell=bash
# @file tests/testcases/cli-check.test.sh
# @brief Testcase for --check.
# @description --check compares the document it would write to --output with
#   the one already there, byte for byte, and never writes it. A stale or
#   missing document fails with a diff on stdout and a note on stderr.

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

# --check compares against --output, so it has nothing to do without one.
tests::run --check source.sh
tests::assert_exitcode 2
tests::assert_stderr_contains '--check needs --output'

# A missing document is reported, and not created.
tests::run --check --output doc.md source.sh
tests::assert_exitcode 1
tests::assert_stderr_contains 'doc.md is missing'
tests::assert_stdout_contains '+# strings.sh'
[[ ! -e doc.md ]] || tests::fail '--check must not create the document'

# An up-to-date document passes silently.
cp expected doc.md
tests::run --check --output doc.md source.sh
tests::assert_exitcode 0
[[ ! -s stdout && ! -s stderr ]] || tests::fail 'an up-to-date check prints nothing'

# A stale document fails with a diff, and is left as it was.
tests::put doc.md << 'MD'
# strings.sh

Old brief.
MD
cp doc.md before
tests::run --check --output=doc.md source.sh
tests::assert_exitcode 1
tests::assert_stderr_contains 'doc.md is out of date'
tests::assert_stdout_contains '-Old brief.'
tests::assert_stdout_contains '+Helpers for text manipulation.'
tests::assert_no_diff before doc.md

# The comparison is byte for byte: a trailing blank line is a difference.
cp expected doc.md
printf '\n' >> doc.md
tests::run --check --output doc.md source.sh
tests::assert_exitcode 1
tests::assert_stderr_contains 'doc.md is out of date'
