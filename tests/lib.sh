# shellcheck shell=bash
# @file tests/lib.sh
# @brief Helpers available to every sh-docs testcase.
# @namespace tests
# @description A testcase runs in its own temporary directory with this file
#   already sourced, so it only has to describe an input, the Markdown it
#   expects, and call `tests::assert`.
#
#   The file is sourced, never run, so it carries no shebang and no strict-mode
#   line of its own: it inherits both from `tests/run_tests`.

# @description Write standard input to a file in the testcase directory.
# @arg $1 string Path of the file to write, relative to the testcase directory
# @stdin The content to write
# @example
#   tests::put input << 'SH'
#   # @file strings.sh
#   SH
function tests::put {
  cat > "$1"
}

# @description Run sh-docs with the given options and collect its output.
#   Standard input is the `input` file when the testcase created one, so a
#   testcase that passes the source as an argument instead does not hang
#   waiting on a terminal.
# @arg $@ any Options and arguments to pass to sh-docs
# @set TESTS_EXITCODE number The exit code sh-docs returned
# @stdout Nothing; the output is captured in the `stdout` file
function tests::run {
  local _stdin=/dev/null
  [[ -f input ]] && _stdin=input

  set +e
  "${SH_DOCS}" "$@" < "${_stdin}" > stdout 2> stderr
  TESTS_EXITCODE=$?
  set -e
}

# @description Fail the testcase with a message and whatever context has been
#   collected so far.
# @arg $1 string The message to report
# @stderr The message, followed by the captured standard error
# @exitcode 1 Always
function tests::fail {
  printf 'assertion failed: %s\n' "$1" >&2
  if [[ -s stderr ]]; then
    printf -- '--- stderr ---\n' >&2
    cat stderr >&2
  fi
  return 1
}

# @description Assert that two files hold the same bytes.
# @arg $1 string Path of the expected file
# @arg $2 string Path of the actual file
# @stderr A unified diff when they differ
# @exitcode 0 The files match
# @exitcode 1 The files differ
function tests::assert_no_diff {
  if ! diff -u "$1" "$2" > diff.out; then
    printf 'assertion failed: %s and %s differ\n' "$1" "$2" >&2
    cat diff.out >&2
    return 1
  fi
}

# @description Assert the exit code of the last `tests::run`.
# @arg $1 number The expected exit code
# @exitcode 0 The code matches
# @exitcode 1 The code differs
function tests::assert_exitcode {
  ((TESTS_EXITCODE == $1)) \
    || tests::fail "expected exit code $1, got ${TESTS_EXITCODE}"
}

# @description Assert that the captured standard output contains a string.
# @arg $1 string The string to look for
# @exitcode 0 The string is present
# @exitcode 1 The string is absent
function tests::assert_stdout_contains {
  grep -qF -- "$1" stdout \
    || tests::fail "stdout does not contain: $1"
}

# @description Assert that the captured standard error contains a string.
# @arg $1 string The string to look for
# @exitcode 0 The string is present
# @exitcode 1 The string is absent
function tests::assert_stderr_contains {
  grep -qF -- "$1" stderr \
    || tests::fail "stderr does not contain: $1"
}

# @description The common case: render `input` with the given options and
#   compare the result with `expected`.
# @arg $@ any Options and arguments to pass to sh-docs
# @exitcode 0 The document matches
# @exitcode 1 sh-docs failed, or the document differs
function tests::assert {
  tests::run "$@"
  tests::assert_exitcode 0
  tests::assert_no_diff expected stdout
}
