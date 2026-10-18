# shellcheck shell=bash
# @file tests/testcases/strict.test.sh
# @brief Testcase for --strict.
# @description --strict reports a tag sh-docs does not know and a public
#   function without `@description`, each with its line, on stderr. The
#   document is still written; the exit status is 1. A private function, one
#   whose name or last `::` part starts with `_`, needs no description, and
#   neither does an `@internal` one.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh
# @namespace strings
# @brieff Helpers.

# @descripton Trim surrounding whitespace.
strings::trim() {
  :
}

strings::lower() {
  :
}

# @description Documented.
# @argument $1 string The text.
strings::upper() {
  :
}

_private() {
  :
}

strings::_helper() {
  :
}

# @internal
strings::hidden() {
  :
}
SH

tests::run --strict
tests::assert_exitcode 1
tests::put expected_stderr << 'TXT'
sh-docs: <stdin>:4: unknown tag @brieff
sh-docs: <stdin>:6: unknown tag @descripton
sh-docs: <stdin>:7: strings::trim has no @description
sh-docs: <stdin>:11: strings::lower has no @description
sh-docs: <stdin>:16: unknown tag @argument
TXT
tests::assert_no_diff expected_stderr stderr
tests::assert_stdout_contains "### \`strings::trim\`"

# The same input passes without --strict, silently.
tests::run
tests::assert_exitcode 0
[[ ! -s stderr ]] || tests::fail 'warnings are only printed with --strict'

# A file input is named in the warnings, and --output is still written.
cp input strings.sh
tests::run --strict --output doc.md strings.sh
tests::assert_exitcode 1
tests::assert_stderr_contains 'sh-docs: strings.sh:4: unknown tag @brieff'
[[ -s doc.md ]] || tests::fail '--strict still writes the document'

# A clean source passes.
tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh

# @description Trim surrounding whitespace.
strings::trim() {
  :
}
SH
tests::run --strict
tests::assert_exitcode 0
[[ ! -s stderr ]] || tests::fail 'a clean source prints no warning'
