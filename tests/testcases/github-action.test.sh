# shellcheck shell=bash
# @file tests/testcases/github-action.test.sh
# @brief Testcase for the script behind the GitHub Action.
# @description `contrib/github-action.sh` reads the inputs of the action from
#   the environment, expands the `files` globs, `**` included, and runs
#   sh-docs. Its exit status is sh-docs's: 1 for a stale document, 2 for an
#   invalid input.

# The inputs the action declares, with check off so the first run writes.
defaults=(env SH_DOCS_BIN="${SH_DOCS:?exported by tests/run_tests}"
  SH_DOCS_OUTPUT_DIR=docs SH_DOCS_CHECK=false SH_DOCS_STRICT=false
  SH_DOCS_INDEX=false SH_DOCS_FORMAT=markdown SH_DOCS_ARGS=)
action="${SH_DOCS_ROOT:?exported by tests/run_tests}/contrib/github-action.sh"

mkdir -p src/nested
tests::put src/a.sh << 'SH'
# @file a.sh
# @brief The first module.
SH
tests::put src/nested/b.sh << 'SH'
# @file b.sh
# @brief The second module.
SH

tests::run_command "${defaults[@]}" SH_DOCS_FILES='src/**/*.sh' SH_DOCS_INDEX=true "${action}"
tests::assert_exitcode 0
for _doc in a b index; do
  [[ -f docs/${_doc}.md ]] || tests::fail "docs/${_doc}.md was not written"
done

tests::run_command "${defaults[@]}" SH_DOCS_FILES='src/**/*.sh' SH_DOCS_INDEX=true SH_DOCS_CHECK=true "${action}"
tests::assert_exitcode 0

printf 'stale\n' >> docs/a.md
tests::run_command "${defaults[@]}" SH_DOCS_FILES='src/**/*.sh' SH_DOCS_INDEX=true SH_DOCS_CHECK=true "${action}"
tests::assert_exitcode 1
tests::assert_stderr_contains 'docs/a.md is out of date'

# Further options are passed through.
tests::run_command "${defaults[@]}" SH_DOCS_FILES='src/a.sh' SH_DOCS_ARGS='--no-emoji --output-dir plain' "${action}"
tests::assert_exitcode 0
if grep -qF '✨' plain/a.md; then
  tests::fail 'SH_DOCS_ARGS did not reach sh-docs'
fi

tests::run_command "${defaults[@]}" SH_DOCS_FILES='' "${action}"
tests::assert_exitcode 2
tests::assert_stderr_contains 'the files input is empty'

tests::run_command "${defaults[@]}" SH_DOCS_FILES='lib/*.sh' "${action}"
tests::assert_exitcode 2
tests::assert_stderr_contains 'lib/*.sh matches no file'

tests::run_command "${defaults[@]}" SH_DOCS_FILES='src/a.sh' SH_DOCS_CHECK=yes "${action}"
tests::assert_exitcode 2
tests::assert_stderr_contains 'check must be true or false, not yes'
