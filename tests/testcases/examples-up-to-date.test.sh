# shellcheck shell=bash
# @file tests/testcases/examples-up-to-date.test.sh
# @brief Testcase that the committed example is current.
# @description The generated example in examples/ is committed, so it can fall behind the
#   source it is generated from without anyone noticing. Regenerate it with
#   `make examples`.

cp "${SH_DOCS_ROOT}/examples/readme-example.md" expected
tests::run "${SH_DOCS_ROOT}/examples/readme-example.sh"
tests::assert_exitcode 0
tests::assert_no_diff expected stdout
