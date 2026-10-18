# shellcheck shell=bash
# @file tests/testcases/strict-args.test.sh
# @brief Testcase for --strict and undocumented positional arguments.
# @description --strict reports a public function whose body reads `$N` or
#   `${N...}` with no `@arg $N`. `@arg $@` or `@arg $*` covers every position.
#   Single-quoted text, comments and escaped dollars are not read, so an awk
#   program's `$1` is not mistaken for an argument. The body ends at the `}` or
#   `)` indented like the declaration, which is how shfmt writes it.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh

# @description Repeat a string.
# @arg $1 string The string.
strings::repeat() {
  local _times="${2:-1}"
  printf '%s' "$1" "$_times"
}

# @description Print the first field.
# @arg $1 string The line.
strings::field() {
  # $2 in a comment is not read.
  awk '{ print $2 }' <<< "$1"
  printf '%s\n' "\$3 is escaped"
}

# @description Pass everything through.
# @arg $@ any The arguments.
strings::all() {
  printf '%s\n' "$1" "$2"
}

# @description One line.
strings::one() { printf '%s\n' "$1"; }

_private() {
  printf '%s\n' "$1"
}

# @description Uses nothing.
# @noargs
strings::none() {
  :
}
SH

tests::run --strict
tests::assert_exitcode 1
tests::put expected_stderr << 'TXT'
sh-docs: <stdin>:7: strings::repeat uses $2 without @arg $2
sh-docs: <stdin>:26: strings::one uses $1 without @arg $1
TXT
tests::assert_no_diff expected_stderr stderr
