# shellcheck shell=bash
# @file tests/testcases/multi-input.test.sh
# @brief Testcase for several inputs and --output-dir.
# @description With --output-dir, sh-docs takes any number of sources and
#   writes one document each, named after the source with its shell extension
#   dropped. --index adds an index.md that lists them with their brief.
#   --check and --strict cover every file and fail if any one fails.

mkdir -p src bin
tests::put src/a.sh << 'SH'
# @file a.sh
# @brief The first module.
SH
tests::put src/b.bash << 'SH'
# @file b.bash
# @brief The second module.
SH
tests::put bin/run << 'SH'
#!/usr/bin/env bash
# @descripton A typo.
SH

tests::run --output-dir docs --index src/a.sh src/b.bash bin/run
tests::assert_exitcode 0
[[ ! -s stdout ]] || tests::fail '--output-dir prints nothing on stdout'
for _doc in a b run index; do
  [[ -f docs/${_doc}.md ]] || tests::fail "docs/${_doc}.md was not written"
done

"${SH_DOCS:?}" src/a.sh > expected
tests::assert_no_diff expected docs/a.md

tests::put expected << 'MD'
# Index

- [a.sh](a.md) — The first module.
- [b.bash](b.md) — The second module.
- [run](run.md)
MD
tests::assert_no_diff expected docs/index.md

# --check reads every document, the index included, and writes none.
tests::run --check --output-dir docs --index src/a.sh src/b.bash bin/run
tests::assert_exitcode 0

printf 'stale\n' >> docs/a.md
printf 'stale\n' >> docs/index.md
cp docs/a.md before
tests::run --check --output-dir docs --index src/a.sh src/b.bash bin/run
tests::assert_exitcode 1
tests::assert_stderr_contains 'docs/a.md is out of date'
tests::assert_stderr_contains 'docs/index.md is out of date'
if grep -qF 'docs/b.md' stderr; then
  tests::fail 'an up-to-date document is not reported'
fi
tests::assert_no_diff before docs/a.md

# --check does not create a missing directory.
tests::run --check --output-dir missing src/a.sh
tests::assert_exitcode 1
tests::assert_stderr_contains 'missing/a.md is missing'
[[ ! -e missing ]] || tests::fail '--check must not create the directory'

# --strict reports per file, writes every document, and fails.
tests::run --strict --output-dir docs src/a.sh bin/run
tests::assert_exitcode 1
tests::assert_stderr_contains 'sh-docs: bin/run:2: unknown tag @descripton'
